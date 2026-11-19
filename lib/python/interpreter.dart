import 'ast.dart';
import 'builtins.dart';
import 'methods.dart';
import 'operators.dart';
import 'parser.dart';
import 'py_error.dart';
import 'trace.dart';
import 'values.dart';

export 'trace.dart';

/// Führt Python-Code aus und zeichnet jeden Schritt mit Erklärung auf.
class Interpreter {
  const Interpreter({this.maxSteps = 3000, this.maxDepth = 50});

  final int maxSteps;
  final int maxDepth;

  RunResult run(String source) {
    final exec = _Exec(maxSteps, maxDepth);
    final List<Stmt> program;
    try {
      program = Parser.parse(source);
    } on PyError catch (e) {
      return RunResult(trace: [exec.startStep()], error: e, isSyntaxError: true);
    }
    exec.trace.add(exec.startStep());
    try {
      exec.block(program);
    } on PyError catch (e) {
      exec.record(e.line, StepKind.error, e.display, count: false);
      return RunResult(trace: exec.trace, error: e);
    }
    return RunResult(trace: exec.trace);
  }
}

class _Frame {
  _Frame(this.function, this.locals);
  final PyFunction function;
  final Map<String, Object?> locals;
  final globalNames = <String>{};
  int loopDepth = 0;
}

class _Break {
  const _Break();
}

class _Continue {
  const _Continue();
}

class _Return {
  const _Return(this.value);
  final Object? value;
}

String _short(String s, [int max = 60]) => s.length <= max ? s : '${s.substring(0, max - 1)}…';
String _r(Object? v) => _short(pyRepr(v));

class _Exec implements PyContext {
  _Exec(this.maxSteps, this.maxDepth);

  final int maxSteps;
  final int maxDepth;
  final trace = <TraceStep>[];
  final globals = <String, Object?>{};
  final frames = <_Frame>[];
  final compScopes = <Map<String, Object?>>[];
  final output = StringBuffer();
  var _topLoopDepth = 0;
  var _steps = 0;
  var _lastReprs = <String, String>{};

  // ---------------- Aufzeichnung ----------------

  TraceStep startStep() => const TraceStep(
    line: null,
    kind: StepKind.start,
    description: 'Bereit! Python liest das Programm von oben nach unten, Zeile für Zeile.',
    variables: [],
    output: '',
  );

  void record(int line, StepKind kind, String description, {bool count = true}) {
    if (count && ++_steps > maxSteps) {
      throw PyError(line, 'Hinweis',
          'Das Programm hat mehr als $maxSteps Schritte gemacht. Ist das eine Endlosschleife? '
          'Prüfe, ob sich die Bedingung irgendwann ändert.');
    }
    final reprs = <String, String>{};
    final vars = <VarView>[];
    void add(String name, Object? value, String? scope) {
      final key = '${scope ?? ''}:$name';
      final repr = value is PyFunction && !value.isLambda ? 'Funktion ${value.name}()' : pyRepr(value);
      reprs[key] = repr;
      vars.add(VarView(
        name: name,
        repr: repr,
        typeName: germanTypeName(value),
        changed: _lastReprs[key] != repr,
        scope: scope,
      ));
    }

    globals.forEach((k, v) => add(k, v, null));
    if (frames.isNotEmpty) {
      final f = frames.last;
      f.locals.forEach((k, v) => add(k, v, f.function.isLambda ? 'lambda' : '${f.function.name}()'));
    }
    _lastReprs = reprs;
    trace.add(TraceStep(
      line: line,
      kind: kind,
      description: description,
      variables: vars,
      output: output.toString(),
    ));
  }

  // ---------------- Variablen ----------------

  _Frame? get _frame => frames.isEmpty ? null : frames.last;

  Object? lookup(String name, int line) {
    for (final scope in compScopes.reversed) {
      if (scope.containsKey(name)) return scope[name];
    }
    final f = _frame;
    if (f != null) {
      if (f.locals.containsKey(name)) return f.locals[name];
      if (f.function.localNames.contains(name) && !f.globalNames.contains(name)) {
        throw PyError(line, 'UnboundLocalError',
            'Die Variable "$name" wird in der Funktion benutzt, bevor sie dort einen Wert hat. '
            'Meinst du die Variable von außen? Dann schreibe am Anfang der Funktion: global $name');
      }
      final closure = f.function.closure;
      if (closure != null && closure.containsKey(name)) return closure[name];
    }
    if (globals.containsKey(name)) return globals[name];
    if (builtinNames.contains(name)) return PyBuiltin(name);

    final lower = name.toLowerCase();
    if (lower != name && (builtinNames.contains(lower) || globals.containsKey(lower))) {
      throw PyError(line, 'NameError',
          '"$name" gibt es nicht. Python unterscheidet Groß- und Kleinschreibung – meintest du "$lower"?');
    }
    throw PyError(line, 'NameError',
        'Die Variable "$name" gibt es noch nicht. Gib ihr zuerst einen Wert, z. B. $name = 0 – '
        'oder meintest du einen Text? Dann brauchst du Anführungszeichen: "$name"');
  }

  void setVar(String name, Object? value) {
    final f = _frame;
    if (f != null && !f.globalNames.contains(name)) {
      f.locals[name] = value;
    } else {
      globals[name] = value;
    }
  }

  bool _hasVar(String name) {
    final f = _frame;
    if (f != null && !f.globalNames.contains(name)) return f.locals.containsKey(name);
    return globals.containsKey(name);
  }

  void assign(Expr target, Object? value, int line) {
    switch (target) {
      case NameExpr(:final name):
        setVar(name, value);
      case IndexExpr():
        Ops.setItem(eval(target.target, line), eval(target.index, line), value, line);
      case TupleExpr(:final items):
        final values = pyIterate(value, line).toList();
        if (values.length != items.length) {
          throw PyError(line, 'ValueError',
              'Links stehen ${items.length} Namen, rechts aber ${values.length} Werte – das muss gleich viele sein.');
        }
        for (var i = 0; i < items.length; i++) {
          assign(items[i], values[i], line);
        }
      default:
        throw PyError(line, 'SyntaxError', 'Diesem Ausdruck kann man nichts zuweisen.');
    }
  }

  // ---------------- Anweisungen ----------------

  void block(List<Stmt> statements) {
    for (final s in statements) {
      _execute(s);
    }
  }

  int get _loopDepth => _frame?.loopDepth ?? _topLoopDepth;
  set _loopDepth(int v) => _frame == null ? _topLoopDepth = v : _frame!.loopDepth = v;

  void _execute(Stmt s) {
    final line = s.line;
    switch (s) {
      case AssignStmt():
        _assign(s);
      case AugAssignStmt():
        _augAssign(s);
      case ExprStmt():
        _exprStatement(s);
      case IfStmt():
        for (var i = 0; i < s.branches.length; i++) {
          final b = s.branches[i];
          final result = pyTruthy(eval(b.condition, b.line));
          final more = i < s.branches.length - 1 || s.elseBody != null;
          record(b.line, StepKind.condition, result
              ? 'Die Bedingung ${b.conditionText} ist True (wahr) → der eingerückte ${b.keyword}-Teil wird ausgeführt.'
              : more
              ? 'Die Bedingung ${b.conditionText} ist False (falsch) → weiter zum nächsten Teil (elif/else).'
              : 'Die Bedingung ${b.conditionText} ist False (falsch) → der eingerückte Teil wird übersprungen.');
          if (result) {
            block(b.body);
            return;
          }
        }
        if (s.elseBody != null) block(s.elseBody!);
      case WhileStmt():
        var round = 0;
        _loopDepth++;
        try {
          while (true) {
            final ok = pyTruthy(eval(s.condition, line));
            if (!ok) {
              record(line, StepKind.loop, round == 0
                  ? 'Die Bedingung ${s.conditionText} ist schon am Anfang False → die Schleife läuft kein einziges Mal.'
                  : 'Die Bedingung ${s.conditionText} ist jetzt False → die while-Schleife endet nach $round Runde(n).');
              break;
            }
            round++;
            record(line, StepKind.loop, 'Die Bedingung ${s.conditionText} ist True → Runde $round der while-Schleife.');
            try {
              block(s.body);
            } on _Continue {
              continue;
            } on _Break {
              break;
            }
          }
        } finally {
          _loopDepth--;
        }
      case ForStmt():
        _for(s);
      case DefStmt():
        final params = [
          for (final p in s.params) s.defaults.containsKey(p) ? '$p=${_r(eval(s.defaults[p]!, line))}' : p,
        ];
        setVar(s.name, PyFunction(
          name: s.name,
          params: s.params,
          defaults: {for (final e in s.defaults.entries) e.key: eval(e.value, line)},
          line: line,
          body: s.body,
          closure: _frame?.locals,
          localNames: _assignedNames(s.body),
        ));
        record(line, StepKind.define,
            'Die Funktion ${s.name}(${params.join(', ')}) wird definiert. Ihr Code läuft erst, wenn sie aufgerufen wird.');
      case ReturnStmt():
        if (_frame == null) throw PyError(line, 'SyntaxError', 'return gibt es nur innerhalb einer Funktion (def).');
        final value = s.value == null ? null : eval(s.value!, line);
        record(line, StepKind.giveBack, s.value == null
            ? 'return beendet die Funktion (ohne Wert, also None).'
            : 'return gibt ${_r(value)} zurück – die Funktion ist hier zu Ende.');
        throw _Return(value);
      case BreakStmt():
        if (_loopDepth == 0) throw PyError(line, 'SyntaxError', 'break gibt es nur innerhalb einer Schleife.');
        record(line, StepKind.loop, 'break: Die Schleife wird sofort beendet.');
        throw const _Break();
      case ContinueStmt():
        if (_loopDepth == 0) throw PyError(line, 'SyntaxError', 'continue gibt es nur innerhalb einer Schleife.');
        record(line, StepKind.loop, 'continue: Der Rest dieser Runde wird übersprungen, weiter mit der nächsten Runde.');
        throw const _Continue();
      case PassStmt():
        record(line, StepKind.other, 'pass bedeutet: Hier passiert nichts. Es ist nur ein Platzhalter.');
      case DelStmt():
        final parts = <String>[];
        for (final t in s.targets) {
          switch (t) {
            case NameExpr(:final name):
              lookup(name, line);
              if (_frame != null && _frame!.locals.containsKey(name)) {
                _frame!.locals.remove(name);
              } else {
                globals.remove(name);
              }
              parts.add('die Variable $name');
            case IndexExpr():
              final key = eval(t.index, line);
              Ops.deleteItem(eval(t.target, line), key, line);
              parts.add('das Element ${_r(key)}');
            default:
              throw PyError(line, 'SyntaxError', 'Mit del kann man Variablen oder Elemente löschen, z. B. del liste[0]');
          }
        }
        record(line, StepKind.assign, 'del löscht ${parts.join(' und ')}.');
      case GlobalStmt():
        _frame?.globalNames.addAll(s.names);
        record(line, StepKind.other, _frame == null
            ? 'global hat außerhalb einer Funktion keine Wirkung.'
            : 'global ${s.names.join(', ')}: In dieser Funktion ist damit die Variable von außen gemeint.');
    }
  }

  void _assign(AssignStmt s) {
    final line = s.line;
    final value = eval(s.value, line);
    final single = s.targets.length == 1 ? s.targets.first : null;
    final String description;
    if (single is NameExpr) {
      final name = single.name;
      final existed = _hasVar(name);
      final old = existed ? lookup(name, line) : null;
      setVar(name, value);
      description = !existed
          ? 'Neue Variable $name: Sie bekommt den Wert ${_r(value)}.'
          : pyRepr(old) == pyRepr(value)
          ? '$name bekommt wieder den Wert ${_r(value)}.'
          : '$name bekommt den neuen Wert ${_r(value)} (vorher ${_r(old)}).';
    } else if (single is IndexExpr) {
      final container = eval(single.target, line);
      final key = eval(single.index, line);
      Ops.setItem(container, key, value, line);
      final name = single.target is NameExpr ? (single.target as NameExpr).name : 'Die Sammlung';
      description = container is PyDict
          ? '$name[${_r(key)}] bekommt den Wert ${_r(value)}. $name ist jetzt ${_r(container)}'
          : 'An Position ${_r(key)} steht jetzt ${_r(value)}. $name ist jetzt ${_r(container)}';
    } else {
      for (final t in s.targets) {
        assign(t, value, line);
      }
      final names = <String>[];
      void collect(Expr e) {
        if (e is NameExpr) names.add('${e.name} = ${_r(lookup(e.name, line))}');
        if (e is TupleExpr) e.items.forEach(collect);
      }
      s.targets.forEach(collect);
      description = 'Zuweisung: ${names.join(', ')}.';
    }
    record(line, StepKind.assign, description);
  }

  void _augAssign(AugAssignStmt s) {
    final line = s.line;
    final old = eval(s.target, line);
    final operand = eval(s.value, line);
    final value = Ops.binary(s.op, old, operand, line);
    assign(s.target, value, line);
    final name = s.target is NameExpr ? (s.target as NameExpr).name : 'Der Wert';
    record(line, StepKind.assign,
        '$name ${s.op}= ${_r(operand)} rechnet ${_r(old)} ${s.op} ${_r(operand)} = ${_r(value)}. $name ist jetzt ${_r(value)}.');
  }

  void _exprStatement(ExprStmt s) {
    final line = s.line;
    final e = s.expr;
    final before = output.length;
    final value = eval(e, line);
    String description;
    if (e is CallExpr && e.callee is NameExpr && (e.callee as NameExpr).name == 'print') {
      final printed = output.toString().substring(before).replaceAll('\n', ' ').trim();
      record(line, StepKind.print, 'print() schreibt in die Ausgabe: ${_short(printed)}');
      return;
    }
    if (e is CallExpr && e.callee is AttributeExpr) {
      final attr = e.callee as AttributeExpr;
      final target = attr.target is NameExpr ? (attr.target as NameExpr).name : null;
      description = '.${attr.name}() wurde ausgeführt';
      if (target != null) {
        description += '. $target ist jetzt ${_r(lookup(target, line))}';
      }
      if (value != null) description += ' – das Ergebnis ${_r(value)} wird nicht gespeichert';
      description += '.';
    } else if (e is CallExpr) {
      description = value == null
          ? 'Der Funktionsaufruf ist fertig.'
          : 'Der Aufruf ist fertig und liefert ${_r(value)} – aber der Wert wird nicht gespeichert oder ausgegeben.';
    } else {
      description = 'Das ergibt ${_r(value)} – aber der Wert wird weder gespeichert noch ausgegeben. '
          'Tipp: print(...) zeigt ihn an.';
    }
    record(line, StepKind.other, description);
  }

  void _for(ForStmt s) {
    final line = s.line;
    final iterable = eval(s.iterable, line);
    final items = pyIterate(iterable, line);
    var round = 0;
    _loopDepth++;
    try {
      for (final item in items) {
        round++;
        if (round > maxSteps) break;
        _bindTargets(s.targets, item, line, setVar);
        final shown = s.targets.length == 1
            ? '${s.targets.first} ist jetzt ${_r(item)}'
            : s.targets.map((t) => '$t = ${_r(lookup(t, line))}').join(', ');
        record(line, StepKind.loop, 'Runde $round der for-Schleife: $shown.');
        try {
          block(s.body);
        } on _Continue {
          continue;
        } on _Break {
          return;
        }
      }
      record(line, StepKind.loop, round == 0
          ? 'Die for-Schleife hat nichts zum Durchlaufen – sie läuft kein einziges Mal.'
          : 'Die for-Schleife ist fertig ($round Runde${round == 1 ? '' : 'n'}). Weiter geht es nach der Schleife.');
    } finally {
      _loopDepth--;
    }
  }

  void _bindTargets(List<String> targets, Object? item, int line, void Function(String, Object?) set) {
    if (targets.length == 1) {
      set(targets.first, item);
      return;
    }
    final parts = pyIterate(item, line).toList();
    if (parts.length != targets.length) {
      throw PyError(line, 'ValueError',
          'Die Schleife hat ${targets.length} Namen, aber jedes Element hat ${parts.length} Werte.');
    }
    for (var i = 0; i < targets.length; i++) {
      set(targets[i], parts[i]);
    }
  }

  static Set<String> _assignedNames(List<Stmt> body) {
    final names = <String>{};
    final globalNames = <String>{};
    void target(Expr e) {
      if (e is NameExpr) names.add(e.name);
      if (e is TupleExpr) e.items.forEach(target);
    }

    void visit(List<Stmt> stmts) {
      for (final s in stmts) {
        switch (s) {
          case AssignStmt():
            s.targets.forEach(target);
          case AugAssignStmt():
            target(s.target);
          case ForStmt():
            names.addAll(s.targets);
            visit(s.body);
          case WhileStmt():
            visit(s.body);
          case IfStmt():
            for (final b in s.branches) {
              visit(b.body);
            }
            if (s.elseBody != null) visit(s.elseBody!);
          case DefStmt():
            names.add(s.name);
          case GlobalStmt():
            globalNames.addAll(s.names);
          default:
            break;
        }
      }
    }

    visit(body);
    return names.difference(globalNames);
  }

  // ---------------- Ausdrücke ----------------

  Object? eval(Expr e, int line) {
    switch (e) {
      case Literal():
        return e.value;
      case FStringExpr():
        final b = StringBuffer();
        for (final part in e.parts) {
          if (part is String) {
            b.write(part);
          } else if (part is FStringField) {
            b.write(formatValue(eval(part.expr, line), part.spec, line));
          }
        }
        return b.toString();
      case NameExpr():
        return lookup(e.name, line);
      case ListExpr():
        return PyList([for (final i in e.items) eval(i, line)]);
      case TupleExpr():
        return PyTuple([for (final i in e.items) eval(i, line)]);
      case SetExpr():
        final items = [for (final i in e.items) eval(i, line)];
        for (final i in items) {
          if (!isHashable(i)) throw PyError(line, 'TypeError', '${pyTypeName(i)} kann nicht in einem Set stehen.');
        }
        return PySet(items);
      case DictExpr():
        final d = PyDict();
        for (var i = 0; i < e.keys.length; i++) {
          final key = eval(e.keys[i], line);
          if (!isHashable(key)) {
            throw PyError(line, 'TypeError', '${pyTypeName(key)} kann kein Schlüssel in einem Dictionary sein.');
          }
          d.map[key] = eval(e.values[i], line);
        }
        return d;
      case ListCompExpr():
        final result = <Object?>[];
        final scope = <String, Object?>{};
        final source = pyIterate(eval(e.iterable, line), line).toList();
        compScopes.add(scope);
        try {
          for (final item in source) {
            _bindTargets(e.targets, item, line, (k, v) => scope[k] = v);
            if (e.condition == null || pyTruthy(eval(e.condition!, line))) {
              result.add(eval(e.element, line));
            }
          }
        } finally {
          compScopes.removeLast();
        }
        return PyList(result);
      case IndexExpr():
        return Ops.getItem(eval(e.target, line), eval(e.index, line), line);
      case SliceExpr():
        return Ops.slice(
          eval(e.target, line),
          e.start == null ? null : eval(e.start!, line),
          e.stop == null ? null : eval(e.stop!, line),
          e.step == null ? null : eval(e.step!, line),
          line,
        );
      case AttributeExpr():
        throw PyError(line, 'SyntaxError', 'Methoden brauchen Klammern, z. B. .${e.name}()');
      case CallExpr():
        final args = [for (final a in e.args) eval(a, line)];
        final kwargs = {for (final k in e.kwargs.entries) k.key: eval(k.value, line)};
        final callee = e.callee;
        if (callee is AttributeExpr) {
          return callMethod(eval(callee.target, line), callee.name, args, kwargs, line, this);
        }
        if (callee is NameExpr && !_isDefined(callee.name)) {
          final suggestion = _suggest(callee.name);
          throw PyError(line, 'NameError',
              'Die Funktion ${callee.name}() gibt es nicht.${suggestion == null ? '' : ' Meintest du $suggestion()?'}');
        }
        return call(eval(callee, line), args, kwargs, line);
      case BinaryExpr():
        if (e.op == 'and') {
          final left = eval(e.left, line);
          return pyTruthy(left) ? eval(e.right, line) : left;
        }
        if (e.op == 'or') {
          final left = eval(e.left, line);
          return pyTruthy(left) ? left : eval(e.right, line);
        }
        return Ops.binary(e.op, eval(e.left, line), eval(e.right, line), line);
      case CompareExpr():
        var left = eval(e.first, line);
        for (var i = 0; i < e.ops.length; i++) {
          final right = eval(e.rest[i], line);
          if (!Ops.compare(e.ops[i], left, right, line)) return false;
          left = right;
        }
        return true;
      case UnaryExpr():
        return Ops.unary(e.op, eval(e.operand, line), line);
      case CondExpr():
        return pyTruthy(eval(e.condition, line)) ? eval(e.then, line) : eval(e.otherwise, line);
      case LambdaExpr():
        return PyFunction(
          name: 'lambda',
          params: e.params,
          defaults: {for (final d in e.defaults.entries) d.key: eval(d.value, line)},
          line: line,
          lambdaBody: e.body,
          closure: _frame?.locals,
        );
    }
  }

  bool _isDefined(String name) =>
      compScopes.any((s) => s.containsKey(name)) ||
      (_frame?.locals.containsKey(name) ?? false) ||
      (_frame?.function.closure?.containsKey(name) ?? false) ||
      globals.containsKey(name) ||
      builtinNames.contains(name);

  /// Ähnlich geschriebener Funktionsname (Tippfehler wie "pront" → "print").
  String? _suggest(String name) {
    final candidates = {...builtinNames, for (final e in globals.entries) if (e.value is PyFunction) e.key};
    String? best;
    var bestDistance = name.length <= 3 ? 2 : 3;
    for (final c in candidates) {
      final d = _distance(name.toLowerCase(), c);
      if (d < bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
    return best;
  }

  static int _distance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  @override
  Object? callValue(Object? fn, List<Object?> args, int line) => call(fn, args, const {}, line);

  Object? call(Object? fn, List<Object?> args, Map<String, Object?> kwargs, int line) {
    switch (fn) {
      case PyBuiltin(:final name):
        if (name == 'print') {
          final sep = kwargs['sep'] ?? ' ';
          final end = kwargs['end'] ?? '\n';
          output
            ..write(args.map(pyStr).join(pyStr(sep)))
            ..write(pyStr(end));
          return null;
        }
        return callBuiltin(name, args, kwargs, line, this);
      case PyFunction():
        return _callFunction(fn, args, kwargs, line);
    }
    throw PyError(line, 'TypeError',
        '${pyTypeName(fn)} (${germanTypeName(fn)}) kann man nicht aufrufen. '
        'Fehlt vielleicht ein Rechenzeichen, z. B. 2 * (3 + 4)?');
  }

  Object? _callFunction(PyFunction f, List<Object?> args, Map<String, Object?> kwargs, int line) {
    final label = f.isLambda ? 'lambda' : '${f.name}()';
    if (frames.length >= maxDepth) {
      throw PyError(line, 'RecursionError',
          'Zu viele Funktionsaufrufe ineinander (mehr als $maxDepth). Ruft sich die Funktion endlos selbst auf?');
    }
    if (args.length > f.params.length) {
      throw PyError(line, 'TypeError',
          '$label hat ${f.params.length} Parameter, aber beim Aufruf stehen ${args.length} Werte in den Klammern.');
    }
    final locals = <String, Object?>{};
    for (var i = 0; i < args.length; i++) {
      locals[f.params[i]] = args[i];
    }
    for (final k in kwargs.entries) {
      if (!f.params.contains(k.key)) throw PyError(line, 'TypeError', '$label hat keinen Parameter namens "${k.key}".');
      locals[k.key] = k.value;
    }
    for (final p in f.params) {
      if (locals.containsKey(p)) continue;
      if (!f.defaults.containsKey(p)) {
        throw PyError(line, 'TypeError', 'Beim Aufruf von $label fehlt der Wert für den Parameter "$p".');
      }
      locals[p] = f.defaults[p];
    }
    final paramText = f.params.isEmpty
        ? 'ohne Parameter'
        : 'mit ${f.params.map((p) => '$p = ${_r(locals[p])}').join(', ')}';

    frames.add(_Frame(f, locals));
    try {
      if (f.isLambda) {
        final value = eval(f.lambdaBody!, f.line);
        record(f.line, StepKind.call, 'lambda wird aufgerufen $paramText und liefert ${_r(value)}.');
        return value;
      }
      record(f.line, StepKind.call, 'Die Funktion $label wird aufgerufen $paramText.');
      try {
        block(f.body!);
      } on _Return catch (r) {
        return r.value;
      } on _Break {
        throw PyError(f.line, 'SyntaxError', 'break steht außerhalb einer Schleife.');
      }
      return null;
    } finally {
      frames.removeLast();
    }
  }
}
