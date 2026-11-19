import 'ast.dart';
import 'builtins.dart';
import 'methods.dart';
import 'modules.dart';
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

  /// [inputs]: Was bei input() „eingetippt“ wird. [files]: Dateien, die es vorher schon gibt.
  RunResult run(String source, {List<String> inputs = const [], Map<String, String> files = const {}}) {
    final exec = _Exec(maxSteps, maxDepth, inputs, files);
    final List<Stmt> program;
    try {
      program = Parser.parse(source);
    } on PyError catch (e) {
      return RunResult(trace: [exec.startStep()], error: e, isSyntaxError: true);
    }
    exec.trace.add(exec.startStep());
    final previousContext = activeContext;
    final previousHook = instanceToString;
    activeContext = exec;
    instanceToString = exec.instanceString;
    try {
      exec.block(program);
    } on PyError catch (e) {
      exec.record(e.line, StepKind.error, e.display, count: false);
      return RunResult(trace: exec.trace, error: e, files: exec.files);
    } finally {
      activeContext = previousContext;
      instanceToString = previousHook;
    }
    return RunResult(trace: exec.trace, files: exec.files);
  }
}

// ---------------- Eingebaute Klassen ----------------

final PyClass objectClass = PyClass('object', const [], {}, true);

/// Fehler-Klassen wie in Python (Name → Elternklasse).
const _exceptionTree = {
  'BaseException': null,
  'Exception': 'BaseException',
  'KeyboardInterrupt': 'BaseException',
  'ArithmeticError': 'Exception',
  'ZeroDivisionError': 'ArithmeticError',
  'OverflowError': 'ArithmeticError',
  'LookupError': 'Exception',
  'IndexError': 'LookupError',
  'KeyError': 'LookupError',
  'ValueError': 'Exception',
  'TypeError': 'Exception',
  'NameError': 'Exception',
  'UnboundLocalError': 'NameError',
  'AttributeError': 'Exception',
  'StopIteration': 'Exception',
  'RuntimeError': 'Exception',
  'RecursionError': 'RuntimeError',
  'NotImplementedError': 'RuntimeError',
  'OSError': 'Exception',
  'FileNotFoundError': 'OSError',
  'FileExistsError': 'OSError',
  'ImportError': 'Exception',
  'ModuleNotFoundError': 'ImportError',
  'AssertionError': 'Exception',
  'SyntaxError': 'Exception',
  'IndentationError': 'SyntaxError',
  // nicht als Name verfügbar, aber abfangbar:
  'JSONDecodeError': 'ValueError',
  'UnsupportedOperation': 'OSError',
  'error': 'Exception',
};

const _hiddenExceptions = {'JSONDecodeError', 'UnsupportedOperation', 'error'};

final Map<String, PyClass> exceptionClasses = () {
  final result = <String, PyClass>{};
  PyClass get(String name) => result.putIfAbsent(name, () {
    final parent = _exceptionTree[name];
    final cls = PyClass(name, [parent == null ? objectClass : get(parent)], {}, true);
    if (parent == null) {
      cls.attrs['__init__'] = PyNative('__init__', (args, kwargs, line) {
        final self = args.first;
        if (self is PyInstance) self.attrs['args'] = PyTuple(args.sublist(1));
        return null;
      });
    }
    return cls;
  });
  _exceptionTree.keys.forEach(get);
  return result;
}();

// ---------------- Laufzeit ----------------

class _Frame {
  _Frame(this.function, this.locals);
  final PyFunction function;
  final Map<String, Object?> locals;
  final globalNames = <String>{};
  final nonlocalNames = <String>{};
  int loopDepth = 0;

  /// Gesammelte Werte bei Generatoren (yield).
  List<Object?>? yields;
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

const _uncatchable = {'Hinweis', 'SyntaxError', 'IndentationError'};

class _Exec implements PyContext {
  _Exec(this.maxSteps, this.maxDepth, List<String> inputs, Map<String, String> files)
    : inputs = List.of(inputs),
      files = Map.of(files);

  final int maxSteps;
  final int maxDepth;
  final List<String> inputs;
  final Map<String, String> files;
  final trace = <TraceStep>[];
  final globals = <String, Object?>{};
  final frames = <_Frame>[];
  final compScopes = <Map<String, Object?>>[];
  final output = StringBuffer();
  final _modules = <String, PyModule>{};
  final _handling = <PyError>[];
  var _topLoopDepth = 0;
  var _steps = 0;
  var _quiet = 0;
  var _lastReprs = <String, String>{};

  // ---------------- Aufzeichnung ----------------

  TraceStep startStep() => const TraceStep(
    line: null,
    kind: StepKind.start,
    description: 'Bereit! Python liest das Programm von oben nach unten, Zeile für Zeile.',
    variables: [],
    output: '',
  );

  /// Kurze, gut lesbare Darstellung für Erklärungen und Variablen-Kästchen.
  /// Ruft nie eigenen Python-Code auf.
  String display(Object? v) {
    _quiet++;
    try {
      return switch (v) {
        PyFunction f when !f.isLambda => f.ownerClass == null ? 'Funktion ${f.name}()' : 'Methode ${f.ownerClass!.name}.${f.name}()',
        PyBoundMethod m => 'Methode ${m.function is PyFunction ? (m.function as PyFunction).name : '?'}()',
        PyClass c => c.isException ? 'Fehler-Klasse ${c.name}' : 'Klasse ${c.name}',
        PyModule m => 'Modul ${m.name}',
        PyNative n => 'Funktion ${n.name}()',
        PyInstance i when i.cls.isException => pyRepr(i),
        PyInstance i => _objectText(i),
        PyFile f => 'Datei "${f.name}" (${f.closed ? 'geschlossen' : 'offen, Modus "${f.mode}"'})',
        PyDateTime d => pyStr(d),
        _ => pyRepr(v),
      };
    } finally {
      _quiet--;
    }
  }

  String _objectText(PyInstance i) {
    if (i.attrs.isEmpty) return '${i.cls.name}-Objekt';
    final prefix = '_${i.cls.name}';
    final parts = [
      for (final e in i.attrs.entries)
        '${e.key.startsWith('${prefix}__') ? e.key.substring(prefix.length) : e.key}=${e.value is PyInstance ? '${(e.value as PyInstance).cls.name}-Objekt' : pyRepr(e.value)}',
    ];
    return '${i.cls.name}-Objekt (${parts.join(', ')})';
  }

  String _r(Object? v) => _short(display(v));

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
      final repr = display(value);
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
      f.locals.forEach((k, v) => add(k, v, f.function.isLambda ? 'lambda' : _label(f.function)));
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

  static String _label(PyFunction f) =>
      f.isLambda ? 'lambda' : (f.ownerClass == null ? '${f.name}()' : '${f.ownerClass!.name}.${f.name}()');

  /// __str__ / __repr__ eigener Klassen (Hook für pyStr/pyRepr).
  String? instanceString(PyInstance i, bool repr) {
    if (_quiet > 0) return null;
    var (found, fn) = i.cls.find(repr ? '__repr__' : '__str__');
    if (!found && !repr) (found, fn) = i.cls.find('__repr__');
    if (!found || fn is! PyFunction) return null;
    final result = _callFunction(fn, [i], const {}, fn.line);
    if (result is! String) {
      throw PyError(fn.line, 'TypeError', '${fn.name}() muss einen Text (str) zurückgeben, nicht ${pyTypeName(result)}.');
    }
    return result;
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
      if (f.function.localNames.contains(name) && !f.globalNames.contains(name) && !f.nonlocalNames.contains(name)) {
        throw PyError(line, 'UnboundLocalError',
            'Die Variable "$name" wird in der Funktion benutzt, bevor sie dort einen Wert hat. '
            'Meinst du die Variable von außen? Dann schreibe am Anfang der Funktion: global $name');
      }
      for (PyFunction? fn = f.function; fn != null; fn = fn.enclosing) {
        final closure = fn.closure;
        if (closure != null && closure.containsKey(name)) return closure[name];
      }
    }
    if (globals.containsKey(name)) return globals[name];
    if (builtinNames.contains(name)) return name == 'object' ? objectClass : PyBuiltin(name);
    final exc = exceptionClasses[name];
    if (exc != null && !_hiddenExceptions.contains(name)) return exc;

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
    if (f != null && f.nonlocalNames.contains(name)) {
      for (PyFunction? fn = f.function; fn != null; fn = fn.enclosing) {
        final closure = fn.closure;
        if (closure != null && closure.containsKey(name)) {
          closure[name] = value;
          return;
        }
      }
    }
    if (f != null && !f.globalNames.contains(name)) {
      f.locals[name] = value;
    } else {
      globals[name] = value;
    }
  }

  bool _hasVar(String name) {
    final f = _frame;
    if (f != null && f.nonlocalNames.contains(name)) return true;
    if (f != null && !f.globalNames.contains(name)) return f.locals.containsKey(name);
    return globals.containsKey(name);
  }

  void assign(Expr target, Object? value, int line) {
    switch (target) {
      case NameExpr(:final name):
        setVar(name, value);
      case IndexExpr():
        Ops.setItem(eval(target.target, line), eval(target.index, line), value, line);
      case AttributeExpr():
        setAttribute(eval(target.target, line), target.name, value, line);
      case SliceExpr():
        _setSlice(target, value, line);
      case TupleExpr(:final items) || ListExpr(:final items):
        final values = pyIterate(value, line).toList();
        final star = items.indexWhere((e) => e is StarredExpr);
        if (star < 0) {
          if (values.length != items.length) {
            throw PyError(line, 'ValueError',
                'Links stehen ${items.length} Namen, rechts aber ${values.length} Werte – das muss gleich viele sein.');
          }
          for (var i = 0; i < items.length; i++) {
            assign(items[i], values[i], line);
          }
        } else {
          final after = items.length - star - 1;
          if (values.length < star + after) {
            throw PyError(line, 'ValueError',
                'Rechts stehen nur ${values.length} Werte – zu wenige für ${items.length - 1} Namen plus *.');
          }
          for (var i = 0; i < star; i++) {
            assign(items[i], values[i], line);
          }
          assign((items[star] as StarredExpr).value, PyList(values.sublist(star, values.length - after)), line);
          for (var i = 0; i < after; i++) {
            assign(items[star + 1 + i], values[values.length - after + i], line);
          }
        }
      default:
        throw PyError(line, 'SyntaxError', 'Diesem Ausdruck kann man nichts zuweisen.');
    }
  }

  (int, int) _sliceRange(SliceExpr s, int length, int line) {
    if (s.step != null) throw PyError(line, 'Hinweis', 'Ausschnitte mit Schrittweite kann man hier nicht ersetzen.');
    int norm(Expr? e, int dflt) {
      if (e == null) return dflt;
      final v = eval(e, line);
      if (v is! int) throw PyError(line, 'TypeError', 'Der Ausschnitt braucht ganze Zahlen.');
      final r = v < 0 ? v + length : v;
      return r.clamp(0, length);
    }

    final a = norm(s.start, 0);
    final b = norm(s.stop, length);
    return (a, b < a ? a : b);
  }

  void _setSlice(SliceExpr s, Object? value, int line) {
    final container = eval(s.target, line);
    if (container is! PyList) throw PyError(line, 'TypeError', 'Nur in Listen kann man einen Ausschnitt ersetzen.');
    final (a, b) = _sliceRange(s, container.items.length, line);
    container.items.replaceRange(a, b, pyIterate(value, line).toList());
  }

  String _text(Expr e) => switch (e) {
    NameExpr(:final name) => name,
    AttributeExpr(:final target, :final name) => '${_text(target)}.$name',
    IndexExpr(:final target, :final index) => '${_text(target)}[${index is Literal ? pyRepr(index.value) : '…'}]',
    SliceExpr(:final target) => '${_text(target)}[…]',
    CallExpr(:final callee) => '${_text(callee)}(…)',
    Literal(:final value) => pyRepr(value),
    _ => 'Der Wert',
  };

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
        var broke = false;
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
              broke = true;
              break;
            }
          }
        } finally {
          _loopDepth--;
        }
        _loopElse(s.elseBody, broke, line);
      case ForStmt():
        _for(s);
      case DefStmt():
        final fn = _makeFunction(s, null);
        final params = [
          for (final p in s.params) s.defaults.containsKey(p) ? '$p=${_r(fn.defaults[p])}' : p,
          if (s.varArgs != null) '*${s.varArgs}',
          if (s.kwArgs != null) '**${s.kwArgs}',
        ];
        record(line, StepKind.define, fn.isGenerator
            ? 'Die Generator-Funktion ${s.name}(${params.join(', ')}) wird definiert. Wegen yield liefert sie beim Aufruf einen Generator.'
            : 'Die Funktion ${s.name}(${params.join(', ')}) wird definiert. Ihr Code läuft erst, wenn sie aufgerufen wird.');
        setVar(s.name, _decorate(fn, s.decorators, s.name, line));
      case ClassStmt():
        setVar(s.name, _defineClass(s));
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
        _delete(s);
      case GlobalStmt():
        _frame?.globalNames.addAll(s.names);
        record(line, StepKind.other, _frame == null
            ? 'global hat außerhalb einer Funktion keine Wirkung.'
            : 'global ${s.names.join(', ')}: In dieser Funktion ist damit die Variable von außen gemeint.');
      case NonlocalStmt():
        if (_frame == null) throw PyError(line, 'SyntaxError', 'nonlocal gibt es nur in einer inneren Funktion.');
        _frame!.nonlocalNames.addAll(s.names);
        record(line, StepKind.other,
            'nonlocal ${s.names.join(', ')}: Gemeint ist die Variable der äußeren Funktion – nicht eine neue lokale.');
      case TryStmt():
        _try(s);
      case RaiseStmt():
        _raise(s);
      case AssertStmt():
        final ok = pyTruthy(eval(s.condition, line));
        if (!ok) {
          final message = s.message == null ? '' : pyStr(eval(s.message!, line));
          final exc = _newException('AssertionError', message.isEmpty ? [] : [message]);
          throw PyError(line, 'AssertionError', message, exception: exc);
        }
        record(line, StepKind.condition, 'assert prüft die Bedingung: Sie ist True, also geht es einfach weiter.');
      case MatchStmt():
        _match(s);
      case ImportStmt():
        _import(s);
      case WithStmt():
        _with(s);
      case YieldStmt():
        final f = _frame;
        if (f == null || f.yields == null) throw PyError(line, 'SyntaxError', 'yield gibt es nur innerhalb einer Funktion.');
        final value = s.value == null ? null : eval(s.value!, line);
        f.yields!.add(value);
        record(line, StepKind.giveBack,
            'yield gibt ${_r(value)} heraus – das ist Wert Nummer ${f.yields!.length} des Generators.');
    }
  }

  PyFunction _makeFunction(DefStmt s, PyClass? owner) => PyFunction(
    name: s.name,
    params: s.params,
    defaults: {for (final e in s.defaults.entries) e.key: eval(e.value, s.line)},
    line: s.line,
    body: s.body,
    closure: _frame?.locals,
    enclosing: _frame?.function,
    localNames: _assignedNames(s.body),
    varArgs: s.varArgs,
    kwArgs: s.kwArgs,
    positionalOnly: s.positionalOnly,
    keywordOnly: s.keywordOnly,
    isGenerator: _containsYield(s.body),
    ownerClass: owner,
  );

  Object? _decorate(Object? value, List<Expr> decorators, String name, int line) {
    var result = value;
    for (final d in decorators.reversed) {
      final decorator = eval(d, line);
      record(line, StepKind.call,
          'Der Dekorator @${_text(d)} bekommt $name und gibt etwas Neues zurück, das ab jetzt $name heißt.');
      result = call(decorator, [result], const {}, line);
    }
    return result;
  }

  PyClass _defineClass(ClassStmt s) {
    final line = s.line;
    final bases = <PyClass>[];
    for (final b in s.bases) {
      final v = eval(b, line);
      if (v is! PyClass) throw PyError(line, 'TypeError', 'Erben kann man nur von einer Klasse, nicht von ${pyTypeName(v)}.');
      bases.add(v);
    }
    final cls = PyClass(s.name, bases.isEmpty ? [objectClass] : bases);
    for (final stmt in s.body) {
      switch (stmt) {
        case DefStmt():
          cls.attrs[stmt.name] = _decorate(_makeFunction(stmt, cls), stmt.decorators, stmt.name, stmt.line);
        case AssignStmt(:final targets) when targets.every((t) => t is NameExpr):
          final value = eval(stmt.value, stmt.line);
          for (final t in targets) {
            cls.attrs[(t as NameExpr).name] = value;
          }
        case ClassStmt():
          cls.attrs[stmt.name] = _defineClass(stmt);
        case PassStmt():
          break;
        case ExprStmt(:final expr) when expr is Literal && expr.value is String:
          break; // Beschreibung (Docstring)
        default:
          throw PyError(stmt.line, 'SyntaxError',
              'In einer Klasse stehen in diesem Spiel nur Methoden (def) und Klassen-Attribute (name = wert).');
      }
    }
    final methods = [for (final e in cls.attrs.entries) if (e.value is PyFunction) '${e.key}()'];
    final attrs = [for (final e in cls.attrs.entries) if (e.value is! PyFunction && e.value is! PyClass) e.key];
    final parents = bases.where((b) => !(b.builtin && b.name == 'object')).map((b) => b.name).toList();
    final parts = [
      'Die Klasse ${s.name} wird definiert – ein Bauplan für Objekte.',
      if (parents.isNotEmpty) 'Sie erbt alles von ${parents.join(' und ')}.',
      if (methods.isNotEmpty) 'Methoden: ${methods.join(', ')}.',
      if (attrs.isNotEmpty) 'Klassen-Attribute: ${attrs.join(', ')}.',
    ];
    record(line, StepKind.define, parts.join(' '));
    return _decorate(cls, s.decorators, s.name, line) as PyClass;
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
      final newObject = value is PyInstance && s.value is CallExpr;
      description = newObject && !existed
          ? 'Neue Variable $name: Sie zeigt auf das neue Objekt ${_r(value)}.'
          : !existed
          ? 'Neue Variable $name: Sie bekommt den Wert ${_r(value)}.'
          : display(old) == display(value)
          ? '$name bekommt wieder den Wert ${_r(value)}.'
          : '$name bekommt den neuen Wert ${_r(value)} (vorher ${_r(old)}).';
    } else if (single is IndexExpr) {
      final container = eval(single.target, line);
      final key = eval(single.index, line);
      Ops.setItem(container, key, value, line);
      final name = _text(single.target);
      description = container is PyDict
          ? '$name[${_r(key)}] bekommt den Wert ${_r(value)}. $name ist jetzt ${_r(container)}'
          : 'An Position ${_r(key)} steht jetzt ${_r(value)}. $name ist jetzt ${_r(container)}';
    } else if (single is AttributeExpr) {
      assign(single, value, line);
      final owner = single.target is NameExpr && (single.target as NameExpr).name == 'self' ? ' (gehört zum Objekt self)' : '';
      description = '${_text(single)} bekommt den Wert ${_r(value)}$owner.';
    } else if (single is SliceExpr) {
      assign(single, value, line);
      description = 'Der Ausschnitt wird ersetzt. ${_text(single.target)} ist jetzt ${_r(eval(single.target, line))}';
    } else {
      for (final t in s.targets) {
        assign(t, value, line);
      }
      final names = <String>[];
      void collect(Expr e) {
        switch (e) {
          case NameExpr(:final name):
            names.add('$name = ${_r(lookup(name, line))}');
          case StarredExpr(:final value):
            collect(value);
          case TupleExpr(:final items) || ListExpr(:final items):
            items.forEach(collect);
          case AttributeExpr():
            names.add('${_text(e)} = ${_r(eval(e, line))}');
          default:
            break;
        }
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
    final name = _text(s.target);
    record(line, StepKind.assign,
        '$name ${s.op}= ${_r(operand)} rechnet ${_r(old)} ${s.op} ${_r(operand)} = ${_r(value)}. $name ist jetzt ${_r(value)}.');
  }

  void _delete(DelStmt s) {
    final line = s.line;
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
        case SliceExpr():
          final container = eval(t.target, line);
          if (container is! PyList) throw PyError(line, 'TypeError', 'Ausschnitte kann man nur aus Listen löschen.');
          final (a, b) = _sliceRange(t, container.items.length, line);
          container.items.removeRange(a, b);
          parts.add('einen Ausschnitt');
        case AttributeExpr():
          final obj = eval(t.target, line);
          final key = _mangle(t.name);
          if (obj is PyInstance && obj.attrs.containsKey(key)) {
            obj.attrs.remove(key);
          } else if (obj is PyClass && obj.attrs.containsKey(t.name)) {
            obj.attrs.remove(t.name);
          } else {
            throw PyError(line, 'AttributeError', '${_text(t)} gibt es nicht – also kann man es auch nicht löschen.');
          }
          parts.add('die Eigenschaft ${_text(t)}');
        default:
          throw PyError(line, 'SyntaxError', 'Mit del kann man Variablen oder Elemente löschen, z. B. del liste[0]');
      }
    }
    record(line, StepKind.assign, 'del löscht ${parts.join(' und ')}.');
  }

  void _exprStatement(ExprStmt s) {
    final line = s.line;
    final e = s.expr;
    if (e is Literal && e.value is String) {
      record(line, StepKind.other,
          'Ein Text, der nirgends gespeichert wird – Python überspringt ihn. So schreibt man oft mehrzeilige Kommentare.');
      return;
    }
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
        final t = lookup(target, line);
        if (t is PyList || t is PyDict || t is PySet) description += '. $target ist jetzt ${_r(t)}';
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
    var broke = false;
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
          broke = true;
          break;
        }
      }
      if (!broke) {
        record(line, StepKind.loop, round == 0
            ? 'Die for-Schleife hat nichts zum Durchlaufen – sie läuft kein einziges Mal.'
            : 'Die for-Schleife ist fertig ($round Runde${round == 1 ? '' : 'n'}). Weiter geht es nach der Schleife.');
      }
    } finally {
      _loopDepth--;
    }
    _loopElse(s.elseBody, broke, line);
  }

  void _loopElse(List<Stmt>? body, bool broke, int line) {
    if (body == null) return;
    if (broke) {
      record(line, StepKind.loop, 'Die Schleife wurde mit break beendet → der else-Teil wird übersprungen.');
      return;
    }
    record(line, StepKind.loop, 'Die Schleife ist ohne break zu Ende gelaufen → jetzt läuft der else-Teil.');
    block(body);
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

  // ---------------- try / raise ----------------

  PyInstance _newException(String type, List<Object?> args) {
    final cls = exceptionClasses[type] ?? exceptionClasses['Exception']!;
    return PyInstance(cls)..attrs['args'] = PyTuple(args);
  }

  PyInstance _exceptionObject(PyError e) {
    final exc = e.exception;
    if (exc is PyInstance) return exc;
    return _newException(e.type, [e.message]);
  }

  bool _matches(PyError e, Object? types, int line) {
    final cls = _exceptionObject(e).cls;
    final list = types is PyTuple ? types.items : [types];
    for (final t in list) {
      if (t is! PyClass || !t.isException) {
        throw PyError(line, 'TypeError', 'Nach except muss eine Fehler-Klasse stehen, z. B. except ValueError:');
      }
      if (cls.isSubclassOf(t)) return true;
    }
    return false;
  }

  void _try(TryStmt s) {
    record(s.line, StepKind.other,
        'try: Python probiert den eingerückten Code aus. Falls dabei ein Fehler passiert, geht es im passenden except-Teil weiter.');
    try {
      var failed = false;
      try {
        block(s.body);
      } on PyError catch (e) {
        if (_uncatchable.contains(e.type)) rethrow;
        ExceptClause? handler;
        for (final h in s.handlers) {
          if (h.types == null || _matches(e, eval(h.types!, h.line), h.line)) {
            handler = h;
            break;
          }
        }
        if (handler == null) rethrow;
        failed = true;
        final text = handler.types == null ? 'except' : 'except ${_text(handler.types!)}';
        record(handler.line, StepKind.condition,
            'Fehler ${e.type} in Zeile ${e.line}! Statt abzustürzen, springt Python zu „$text“ und führt diesen Teil aus.');
        if (handler.name != null) setVar(handler.name!, _exceptionObject(e));
        _handling.add(e);
        try {
          block(handler.body);
        } finally {
          _handling.removeLast();
        }
      }
      if (!failed && s.elseBody != null) {
        record(s.line, StepKind.condition, 'Im try-Teil gab es keinen Fehler → jetzt läuft der else-Teil.');
        block(s.elseBody!);
      }
    } finally {
      if (s.finallyBody != null) {
        record(s.finallyLine!, StepKind.other, 'finally: Dieser Teil läuft immer – egal, ob es einen Fehler gab oder nicht.');
        block(s.finallyBody!);
      }
    }
  }

  void _raise(RaiseStmt s) {
    final line = s.line;
    if (s.value == null) {
      if (_handling.isEmpty) throw PyError(line, 'RuntimeError', 'raise ohne Fehler geht nur in einem except-Teil.');
      record(line, StepKind.other, 'raise ohne Wert: Der gerade abgefangene Fehler wird weitergereicht.');
      throw _handling.last;
    }
    var v = eval(s.value!, line);
    if (v is PyClass && v.isException) v = _instantiate(v, const [], const {}, line);
    if (v is! PyInstance || !v.cls.isException) {
      throw PyError(line, 'TypeError', 'Mit raise kann man nur Fehler auslösen, z. B. raise ValueError("Zu klein")');
    }
    final message = pyStr(v);
    record(line, StepKind.other, 'raise löst absichtlich den Fehler ${v.cls.name} aus${message.isEmpty ? '' : ': $message'}');
    throw PyError(line, v.cls.name, message, exception: v);
  }

  // ---------------- match ----------------

  void _match(MatchStmt s) {
    final subject = eval(s.subject, s.line);
    record(s.line, StepKind.condition,
        'match vergleicht ${s.subjectText} (also ${_r(subject)}) der Reihe nach mit jedem case.');
    for (final c in s.cases) {
      var matched = false;
      for (final p in c.patterns) {
        switch (p) {
          case CapturePattern(:final name):
            if (name != null) setVar(name, subject);
            matched = true;
          case ValuePattern(:final value):
            matched = pyEquals(eval(value, c.line), subject);
        }
        if (matched) break;
      }
      if (matched && c.guard != null) matched = pyTruthy(eval(c.guard!, c.line));
      final wildcard = c.patterns.length == 1 && c.patterns.first is CapturePattern;
      record(c.line, StepKind.condition, matched
          ? wildcard
                ? 'case ${c.patternText} passt immer (für alle übrigen Fälle) → dieser Teil wird ausgeführt.'
                : 'case ${c.patternText} passt → dieser Teil wird ausgeführt, die anderen nicht.'
          : 'case ${c.patternText} passt nicht → weiter zum nächsten case.');
      if (matched) {
        block(c.body);
        return;
      }
    }
  }

  // ---------------- import / with ----------------

  PyModule _module(String name, int line) {
    final cached = _modules[name];
    if (cached != null) return cached;
    final m = createModule(name, files);
    if (m == null) {
      throw PyError(line, 'ModuleNotFoundError',
          'Das Modul "$name" gibt es in diesem Spiel nicht. Hier gibt es: ${moduleNames.join(', ')}.');
    }
    return _modules[name] = m;
  }

  void _import(ImportStmt s) {
    final line = s.line;
    final module = _module(s.module, line);
    if (s.names == null) {
      final top = s.module.split('.').first;
      setVar(s.alias ?? top, s.alias != null || top == s.module ? module : _module(top, line));
      record(line, StepKind.define, s.alias == null
          ? 'import ${s.module} lädt das Modul ${s.module}. Seine Funktionen benutzt du mit ${s.module}.name, z. B. ${_example(s.module)}.'
          : 'import ${s.module} as ${s.alias}: Das Modul heißt in diesem Programm jetzt kürzer ${s.alias}.');
      return;
    }
    final names = s.names!;
    if (names.containsKey('*')) {
      module.attrs.forEach(setVar);
      record(line, StepKind.define, 'from ${s.module} import *: Alles aus ${s.module} ist jetzt direkt benutzbar.');
      return;
    }
    for (final e in names.entries) {
      if (!module.attrs.containsKey(e.key)) {
        throw PyError(line, 'ImportError', 'Im Modul ${s.module} gibt es "${e.key}" nicht.');
      }
      setVar(e.value, module.attrs[e.key]);
    }
    record(line, StepKind.define,
        'from ${s.module} import ${names.keys.join(', ')}: Diese Namen kannst du jetzt direkt benutzen – ohne "${s.module}." davor.');
  }

  static String _example(String module) => switch (module) {
    'math' => 'math.sqrt(16)',
    'json' => 'json.dumps(daten)',
    'datetime' => 'datetime.date(2025, 1, 1)',
    're' => 're.findall(muster, text)',
    'os' => 'os.remove("datei.txt")',
    _ => '$module.name',
  };

  void _with(WithStmt s) {
    final line = s.line;
    final v = eval(s.value, line);
    if (v is PyFile) {
      if (s.name != null) setVar(s.name!, v);
      record(line, StepKind.assign,
          'with öffnet die Datei "${v.name}"${s.name == null ? '' : ' (Name ${s.name})'} und schließt sie am Ende des Blocks automatisch.');
      try {
        block(s.body);
      } finally {
        v.closed = true;
      }
      record(line, StepKind.other, 'Der with-Block ist zu Ende → die Datei "${v.name}" wird automatisch geschlossen.');
      return;
    }
    if (v is PyInstance && v.cls.find('__enter__').$1 && v.cls.find('__exit__').$1) {
      final entered = callMethodOf(v, '__enter__', [], line);
      if (s.name != null) setVar(s.name!, entered);
      try {
        block(s.body);
      } finally {
        callMethodOf(v, '__exit__', [null, null, null], line);
      }
      return;
    }
    throw PyError(line, 'TypeError', 'with funktioniert hier nur mit Dateien, z. B. with open("datei.txt") as f:');
  }

  // ---------------- Namensanalyse ----------------

  static Set<String> _assignedNames(List<Stmt> body) {
    final names = <String>{};
    final excluded = <String>{};
    void target(Expr e) {
      switch (e) {
        case NameExpr(:final name):
          names.add(name);
        case StarredExpr(:final value):
          target(value);
        case TupleExpr(:final items) || ListExpr(:final items):
          items.forEach(target);
        default:
          break;
      }
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
            if (s.elseBody != null) visit(s.elseBody!);
          case WhileStmt():
            visit(s.body);
            if (s.elseBody != null) visit(s.elseBody!);
          case IfStmt():
            for (final b in s.branches) {
              visit(b.body);
            }
            if (s.elseBody != null) visit(s.elseBody!);
          case TryStmt():
            visit(s.body);
            for (final h in s.handlers) {
              if (h.name != null) names.add(h.name!);
              visit(h.body);
            }
            if (s.elseBody != null) visit(s.elseBody!);
            if (s.finallyBody != null) visit(s.finallyBody!);
          case WithStmt():
            if (s.name != null) names.add(s.name!);
            visit(s.body);
          case MatchStmt():
            for (final c in s.cases) {
              for (final p in c.patterns) {
                if (p is CapturePattern && p.name != null) names.add(p.name!);
              }
              visit(c.body);
            }
          case ImportStmt():
            if (s.names == null) {
              names.add(s.alias ?? s.module.split('.').first);
            } else {
              names.addAll(s.names!.values.where((n) => n != '*'));
            }
          case DefStmt():
            names.add(s.name);
          case ClassStmt():
            names.add(s.name);
          case GlobalStmt():
            excluded.addAll(s.names);
          case NonlocalStmt():
            excluded.addAll(s.names);
          default:
            break;
        }
      }
    }

    visit(body);
    return names.difference(excluded);
  }

  static bool _containsYield(List<Stmt> body) {
    for (final s in body) {
      final found = switch (s) {
        YieldStmt() => true,
        ForStmt() => _containsYield(s.body),
        WhileStmt() => _containsYield(s.body),
        IfStmt() => s.branches.any((b) => _containsYield(b.body)) || (s.elseBody != null && _containsYield(s.elseBody!)),
        TryStmt() => _containsYield(s.body) ||
            s.handlers.any((h) => _containsYield(h.body)) ||
            (s.elseBody != null && _containsYield(s.elseBody!)) ||
            (s.finallyBody != null && _containsYield(s.finallyBody!)),
        WithStmt() => _containsYield(s.body),
        MatchStmt() => s.cases.any((c) => _containsYield(c.body)),
        _ => false,
      };
      if (found) return true;
    }
    return false;
  }

  // ---------------- Attribute ----------------

  /// Namen wie __alter werden in Klassen „versteckt“ (wie in Python).
  String _mangle(String name) {
    if (!name.startsWith('__') || name.endsWith('__')) return name;
    final owner = _frame?.function.ownerClass;
    return owner == null ? name : '_${owner.name}$name';
  }

  Object? _bind(Object? self, Object? v) => v is PyFunction || v is PyNative ? PyBoundMethod(self, v) : v;

  @override
  Object? getAttribute(Object? target, String name, int line) {
    switch (target) {
      case PyInstance():
        if (name == '__class__') return target.cls;
        if (name == '__dict__') return PyDict()..map.addAll(target.attrs);
        final key = _mangle(name);
        if (target.attrs.containsKey(key)) return target.attrs[key];
        final (found, v) = target.cls.find(key);
        if (found) return _bind(target, v);
        if (name.startsWith('__') && !name.endsWith('__') && target.attrs.containsKey('_${target.cls.name}$name')) {
          throw PyError(line, 'AttributeError',
              '$name ist privat (zwei Unterstriche am Anfang). Von außerhalb der Klasse kommt man nicht heran.');
        }
        throw PyError(line, 'AttributeError', 'Das ${target.cls.name}-Objekt hat keine Eigenschaft oder Methode "$name".');
      case PyClass():
        if (name == '__name__') return target.name;
        final (found, v) = target.find(name);
        if (found) return v;
        throw PyError(line, 'AttributeError', 'Die Klasse ${target.name} hat kein Attribut "$name".');
      case PySuper():
        final self = target.self;
        final mro = self is PyInstance ? self.cls.mro : (self is PyClass ? self.mro : <PyClass>[]);
        final start = mro.indexOf(target.start);
        for (final c in mro.skip(start + 1)) {
          if (c.attrs.containsKey(name)) return _bind(self, c.attrs[name]);
        }
        if (name == '__init__') return PyNative('__init__', (a, k, l) => null);
        throw PyError(line, 'AttributeError', 'Die Elternklasse hat keine Methode "$name".');
      case PyModule():
        if (target.attrs.containsKey(name)) return target.attrs[name];
        throw PyError(line, 'AttributeError', 'Das Modul ${target.name} hat kein "$name".');
      case PyNative() when target.attrs.containsKey(name):
        return target.attrs[name];
      case PyDateTime(:final value):
        final v = switch (name) {
          'year' => value.year,
          'month' => value.month,
          'day' => value.day,
          'hour' => value.hour,
          'minute' => value.minute,
          'second' => value.second,
          'microsecond' => value.millisecond * 1000 + value.microsecond,
          _ => null,
        };
        if (v != null) return v;
      case PyFile():
        switch (name) {
          case 'name':
            return target.name;
          case 'mode':
            return target.mode;
          case 'closed':
            return target.closed;
        }
      case PyReMatch() when name == 'string':
        return target.string;
      case PyType() when name == '__name__':
        return target.name;
      case PyFunction() when name == '__name__':
        return target.name;
      case PyBuiltin() when name == '__name__':
        return target.name;
      case PyBuiltin() when const {'str', 'list', 'dict', 'set', 'tuple', 'int', 'float'}.contains(target.name):
        // z. B. key=str.lower
        return PyNative('${target.name}.$name', (a, k, l) {
          if (a.isEmpty) throw PyError(l, 'TypeError', '${target.name}.$name() braucht einen Wert.');
          return callMethod(a.first, name, a.sublist(1), k, l, this);
        });
    }
    if (target is PyBuiltin || target is PyFunction || target is PyNative || target == null || isNumber(target)) {
      throw PyError(line, 'AttributeError', '${pyTypeName(target)} (${germanTypeName(target)}) hat kein Attribut "$name".');
    }
    // Methode ohne Aufruf, z. B. f = text.upper
    return PyNative(name, (a, k, l) => callMethod(target, name, a, k, l, this), typeLabel: 'builtin_function_or_method');
  }

  @override
  void setAttribute(Object? target, String name, Object? value, int line) {
    switch (target) {
      case PyInstance():
        target.attrs[_mangle(name)] = value;
        return;
      case PyClass():
        target.attrs[name] = value;
        return;
    }
    throw PyError(line, 'AttributeError',
        '${pyTypeName(target)} (${germanTypeName(target)}) kann man keine eigene Eigenschaft "$name" geben.');
  }

  @override
  Iterable<Object?> iterateObject(PyInstance object, int line) sync* {
    if (!object.cls.find('__iter__').$1) {
      throw PyError(line, 'TypeError',
          'Ein ${object.cls.name}-Objekt kann man nicht durchlaufen. Dafür braucht die Klasse __iter__() und __next__().');
    }
    final it = callMethodOf(object, '__iter__', [], line);
    if (it is! PyInstance) {
      yield* pyIterate(it, line);
      return;
    }
    while (true) {
      Object? v;
      try {
        v = callMethodOf(it, '__next__', [], line);
      } on PyError catch (e) {
        if (e.type == 'StopIteration') return;
        rethrow;
      }
      yield v;
    }
  }

  @override
  Object? callMethodOf(PyInstance object, String name, List<Object?> args, int line) =>
      call(getAttribute(object, name, line), args, const {}, line);

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
        return PyList(_items(e.items, line));
      case TupleExpr():
        return PyTuple(_items(e.items, line));
      case SetExpr():
        final items = _items(e.items, line);
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
      case CompExpr():
        return _comprehension(e, line);
      case StarredExpr():
        throw PyError(line, 'SyntaxError', 'Ein * vor einem Wert geht nur in Aufrufen, Listen oder links vom "=".');
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
        return getAttribute(eval(e.target, line), e.name, line);
      case CallExpr():
        return _evalCall(e, line);
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
          enclosing: _frame?.function,
        );
    }
  }

  List<Object?> _items(List<Expr> items, int line) => [
    for (final i in items)
      if (i is StarredExpr) ...pyIterate(eval(i.value, line), line) else eval(i, line),
  ];

  Object? _comprehension(CompExpr e, int line) {
    final results = <Object?>[];
    final values = <Object?>[];
    final scope = <String, Object?>{};
    compScopes.add(scope);
    void run(int i) {
      if (i == e.clauses.length) {
        results.add(eval(e.element, line));
        if (e.value != null) values.add(eval(e.value!, line));
        return;
      }
      switch (e.clauses[i]) {
        case CompFor(:final targets, :final iterable):
          for (final item in pyIterate(eval(iterable, line), line).toList()) {
            _bindTargets(targets, item, line, (k, v) => scope[k] = v);
            run(i + 1);
          }
        case CompIf(:final condition):
          if (pyTruthy(eval(condition, line))) run(i + 1);
      }
    }

    try {
      run(0);
    } finally {
      compScopes.removeLast();
    }
    switch (e.kind) {
      case CompKind.list:
        return PyList(results);
      case CompKind.set:
        for (final r in results) {
          if (!isHashable(r)) throw PyError(line, 'TypeError', '${pyTypeName(r)} kann nicht in einem Set stehen.');
        }
        return PySet(results);
      case CompKind.dict:
        final d = PyDict();
        for (var i = 0; i < results.length; i++) {
          d.map[results[i]] = values[i];
        }
        return d;
      case CompKind.generator:
        return PyIterator(results, 'generator');
    }
  }

  Object? _evalCall(CallExpr e, int line) {
    final callee = e.callee;
    if (callee is NameExpr && callee.name == 'super' && !_isDefined('super', userOnly: true)) {
      final f = _frame;
      final owner = f?.function.ownerClass;
      if (f == null || owner == null || f.function.params.isEmpty) {
        throw PyError(line, 'RuntimeError', 'super() geht nur in einer Methode einer Klasse.');
      }
      return PySuper(owner, f.locals[f.function.params.first]);
    }
    final args = _items(e.args, line);
    final kwargs = <String, Object?>{for (final k in e.kwargs.entries) k.key: eval(k.value, line)};
    for (final s in e.starKwargs) {
      final d = eval(s, line);
      if (d is! PyDict) throw PyError(line, 'TypeError', 'Nach ** muss ein Dictionary stehen.');
      for (final entry in d.map.entries) {
        if (entry.key is! String) throw PyError(line, 'TypeError', 'Bei ** müssen die Schlüssel Texte sein.');
        kwargs[entry.key as String] = entry.value;
      }
    }
    if (callee is AttributeExpr) {
      final target = eval(callee.target, line);
      if (target is PyBuiltin && target.name == 'dict' && callee.name == 'fromkeys') {
        return callMethod(PyDict(), 'fromkeys', args, kwargs, line, this);
      }
      if (target is PyInstance || target is PyClass || target is PyModule || target is PySuper || target is PyNative) {
        return call(getAttribute(target, callee.name, line), args, kwargs, line);
      }
      return callMethod(target, callee.name, args, kwargs, line, this);
    }
    if (callee is NameExpr && !_isDefined(callee.name)) {
      final suggestion = _suggest(callee.name);
      throw PyError(line, 'NameError',
          'Die Funktion ${callee.name}() gibt es nicht.${suggestion == null ? '' : ' Meintest du $suggestion()?'}');
    }
    return call(eval(callee, line), args, kwargs, line);
  }

  bool _isDefined(String name, {bool userOnly = false}) {
    if (compScopes.any((s) => s.containsKey(name))) return true;
    final f = _frame;
    if (f != null) {
      if (f.locals.containsKey(name)) return true;
      for (PyFunction? fn = f.function; fn != null; fn = fn.enclosing) {
        if (fn.closure?.containsKey(name) ?? false) return true;
      }
    }
    if (globals.containsKey(name)) return true;
    if (userOnly) return false;
    return builtinNames.contains(name) || (exceptionClasses.containsKey(name) && !_hiddenExceptions.contains(name));
  }

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
        switch (name) {
          case 'print':
            final sep = kwargs['sep'] ?? ' ';
            final end = kwargs['end'] ?? '\n';
            output
              ..write(args.map(pyStr).join(pyStr(sep)))
              ..write(pyStr(end));
            return null;
          case 'input':
            if (inputs.isEmpty) {
              throw PyError(line, 'Hinweis',
                  'input() wartet auf eine Eingabe – hier tippt aber niemand etwas ein. Gib der Variablen direkt einen Wert.');
            }
            final value = inputs.removeAt(0);
            output.write('${args.isEmpty ? '' : pyStr(args.first)}$value\n');
            return value;
          case 'open':
            return _open(args, kwargs, line);
          case 'super':
            throw PyError(line, 'RuntimeError', 'super() geht nur in einer Methode einer Klasse.');
        }
        return callBuiltin(name, args, kwargs, line, this);
      case PyFunction():
        return _callFunction(fn, args, kwargs, line);
      case PyBoundMethod():
        return call(fn.function, [fn.self, ...args], kwargs, line);
      case PyClass():
        if (fn.builtin && fn.name == 'object') {
          if (args.isNotEmpty) throw PyError(line, 'TypeError', 'object() nimmt keine Werte.');
          return PyInstance(fn);
        }
        return _instantiate(fn, args, kwargs, line);
      case PyNative():
        return fn.fn(args, kwargs, line);
      case PyInstance() when fn.cls.find('__call__').$1:
        return call(getAttribute(fn, '__call__', line), args, kwargs, line);
    }
    throw PyError(line, 'TypeError',
        '${pyTypeName(fn)} (${germanTypeName(fn)}) kann man nicht aufrufen. '
        'Fehlt vielleicht ein Rechenzeichen, z. B. 2 * (3 + 4)?');
  }

  PyInstance _instantiate(PyClass cls, List<Object?> args, Map<String, Object?> kwargs, int line) {
    final obj = PyInstance(cls);
    final (found, init) = cls.find('__init__');
    if (found && init != null) {
      final result = call(init, [obj, ...args], kwargs, line);
      if (result != null) throw PyError(line, 'TypeError', '__init__() darf nichts zurückgeben (kein return mit Wert).');
    } else if (args.isNotEmpty || kwargs.isNotEmpty) {
      throw PyError(line, 'TypeError',
          '${cls.name}() nimmt keine Werte an – dafür bräuchte die Klasse eine Methode __init__().');
    }
    return obj;
  }

  PyFile _open(List<Object?> args, Map<String, Object?> kwargs, int line) {
    if (args.isEmpty) throw PyError(line, 'TypeError', 'open() braucht einen Dateinamen, z. B. open("notizen.txt")');
    final name = args[0];
    final mode = args.length > 1 ? args[1] : (kwargs['mode'] ?? 'r');
    if (name is! String || mode is! String) throw PyError(line, 'TypeError', 'Dateiname und Modus müssen Texte sein.');
    if (mode.contains('b')) throw PyError(line, 'Hinweis', 'Binärdateien ("b") gibt es in diesem Spiel nicht.');
    final kind = mode.replaceAll('t', '').replaceAll('+', '');
    switch (kind) {
      case 'r':
        if (!files.containsKey(name)) {
          throw PyError(line, 'FileNotFoundError', 'Die Datei "$name" gibt es nicht.');
        }
      case 'x':
        if (files.containsKey(name)) {
          throw PyError(line, 'FileExistsError', 'Die Datei "$name" gibt es schon – mit "x" wird nur eine neue erstellt.');
        }
        files[name] = '';
      case 'a':
        files.putIfAbsent(name, () => '');
      case 'w':
        break;
      default:
        throw PyError(line, 'ValueError', 'Den Modus "$mode" gibt es nicht. Benutze "r", "w", "a" oder "x".');
    }
    return PyFile(name, mode, files);
  }

  Object? _callFunction(PyFunction f, List<Object?> args, Map<String, Object?> kwargs, int line) {
    final label = _label(f);
    if (frames.length >= maxDepth) {
      throw PyError(line, 'RecursionError',
          'Zu viele Funktionsaufrufe ineinander (mehr als $maxDepth). Ruft sich die Funktion endlos selbst auf?');
    }
    final positional = [for (final p in f.params) if (!f.keywordOnly.contains(p)) p];
    if (args.length > positional.length && f.varArgs == null) {
      throw PyError(line, 'TypeError',
          '$label hat ${positional.length} Parameter, aber beim Aufruf stehen ${args.length} Werte in den Klammern.');
    }
    final locals = <String, Object?>{};
    for (var i = 0; i < args.length && i < positional.length; i++) {
      locals[positional[i]] = args[i];
    }
    final extraKw = PyDict();
    for (final k in kwargs.entries) {
      final index = f.params.indexOf(k.key);
      if (index >= 0 && index >= f.positionalOnly) {
        if (locals.containsKey(k.key)) {
          throw PyError(line, 'TypeError', '$label bekommt für "${k.key}" zwei Werte – einmal per Position und einmal per Name.');
        }
        locals[k.key] = k.value;
      } else if (f.kwArgs != null) {
        extraKw.map[k.key] = k.value;
      } else if (index >= 0) {
        throw PyError(line, 'TypeError', 'Den Parameter "${k.key}" von $label darf man nicht per Name übergeben (er steht vor dem /).');
      } else {
        throw PyError(line, 'TypeError', '$label hat keinen Parameter namens "${k.key}".');
      }
    }
    for (final p in f.params) {
      if (locals.containsKey(p)) continue;
      if (!f.defaults.containsKey(p)) {
        throw PyError(line, 'TypeError', f.keywordOnly.contains(p)
            ? 'Beim Aufruf von $label fehlt "$p" – dieser Parameter muss mit Namen übergeben werden: $p=...'
            : 'Beim Aufruf von $label fehlt der Wert für den Parameter "$p".');
      }
      locals[p] = f.defaults[p];
    }
    if (f.varArgs != null) locals[f.varArgs!] = PyTuple(args.length > positional.length ? args.sublist(positional.length) : []);
    if (f.kwArgs != null) locals[f.kwArgs!] = extraKw;
    final shown = [...f.params, ?f.varArgs, ?f.kwArgs];
    final paramText = shown.isEmpty ? 'ohne Parameter' : 'mit ${shown.map((p) => '$p = ${_r(locals[p])}').join(', ')}';

    final frame = _Frame(f, locals);
    if (f.isGenerator) frame.yields = [];
    frames.add(frame);
    try {
      if (f.isLambda) {
        final value = eval(f.lambdaBody!, f.line);
        record(f.line, StepKind.call, 'lambda wird aufgerufen $paramText und liefert ${_r(value)}.');
        return value;
      }
      final kind = f.ownerClass == null ? 'Die Funktion' : 'Die Methode';
      record(f.line, StepKind.call, f.name == '__init__' && f.ownerClass != null
          ? 'Ein neues ${f.ownerClass!.name}-Objekt entsteht: __init__() richtet es ein ($paramText).'
          : '$kind $label wird aufgerufen $paramText.');
      try {
        block(f.body!);
      } on _Return catch (r) {
        if (!f.isGenerator) return r.value;
      } on _Break {
        throw PyError(f.line, 'SyntaxError', 'break steht außerhalb einer Schleife.');
      }
      if (f.isGenerator) {
        final values = frame.yields!;
        record(f.line, StepKind.giveBack,
            'Der Generator $label ist bereit. Er liefert nacheinander: ${_short(values.map(display).join(', '))}');
        return PyIterator(values, 'generator');
      }
      return null;
    } finally {
      frames.removeLast();
    }
  }
}
