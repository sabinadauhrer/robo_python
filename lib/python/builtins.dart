import 'operators.dart';
import 'py_error.dart';
import 'values.dart';

/// Was eingebaute Funktionen und Methoden vom Interpreter brauchen.
abstract interface class PyContext {
  /// Ruft eine Python-Funktion auf (z. B. für sorted(key=...)).
  Object? callValue(Object? fn, List<Object?> args, int line);
}

const builtinNames = {
  'print', 'len', 'str', 'int', 'float', 'bool', 'type', 'range', 'list', 'tuple', 'set', 'dict',
  'abs', 'min', 'max', 'sum', 'round', 'sorted', 'reversed', 'enumerate', 'zip', 'iter', 'next',
  'isinstance', 'input', 'map', 'filter', 'repr', 'ord', 'chr',
};

/// Typnamen, die auch als Funktionen existieren (für isinstance).
const _typeFunctions = {'int', 'float', 'str', 'bool', 'list', 'tuple', 'set', 'dict'};

PyError _type(int line, String message) => PyError(line, 'TypeError', message);

String _t(Object? v) => '${pyTypeName(v)} (${germanTypeName(v)})';

/// Durchläuft einen Wert wie eine for-Schleife.
Iterable<Object?> pyIterate(Object? v, int line) => switch (v) {
  String s => s.split(''),
  PyList l => List.of(l.items),
  PyTuple t => t.items,
  PyDict d => List.of(d.map.keys),
  PySet s => List.of(s.items),
  PyRange r => r.values,
  PyDictView dv => List.of(dv.items),
  PyIterator it => _drain(it),
  _ => throw _type(line, '${_t(v)} kann man nicht durchlaufen (nicht "iterierbar").'),
};

Iterable<Object?> _drain(PyIterator it) sync* {
  while (true) {
    final v = it.next();
    if (identical(v, PyIterator.exhausted)) return;
    yield v;
  }
}

void _argCount(String name, List<Object?> args, int min, int max, int line) {
  if (args.length < min || args.length > max) {
    final expected = min == max ? '$min' : '$min bis $max';
    throw _type(line, '$name() braucht $expected Wert(e) in den Klammern, bekommen hat es ${args.length}.');
  }
}

int _asInt(Object? v, String what, int line) {
  if (v is int) return v;
  if (v is bool) return v ? 1 : 0;
  throw _type(line, '$what muss eine ganze Zahl sein, nicht ${_t(v)}.');
}

Object? callBuiltin(String name, List<Object?> args, Map<String, Object?> kwargs, int line, PyContext ctx) {
  switch (name) {
    case 'len':
      _argCount(name, args, 1, 1, line);
      final v = args[0];
      return switch (v) {
        String s => s.length,
        PyList l => l.items.length,
        PyTuple t => t.items.length,
        PyDict d => d.map.length,
        PySet s => s.items.length,
        PyRange r => r.length,
        PyDictView dv => dv.items.length,
        _ => throw _type(line, '${_t(v)} hat keine Länge.'),
      };
    case 'str':
      _argCount(name, args, 0, 1, line);
      return args.isEmpty ? '' : pyStr(args[0]);
    case 'int':
      _argCount(name, args, 0, 1, line);
      if (args.isEmpty) return 0;
      final v = args[0];
      if (v is int) return v;
      if (v is bool) return v ? 1 : 0;
      if (v is PyFloat) return v.value.truncate();
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        if (parsed == null) {
          throw PyError(line, 'ValueError', 'int() kann ${pyRepr(v)} nicht in eine ganze Zahl umwandeln.');
        }
        return parsed;
      }
      throw _type(line, 'int() kann ${_t(v)} nicht umwandeln.');
    case 'float':
      _argCount(name, args, 0, 1, line);
      if (args.isEmpty) return const PyFloat(0);
      final v = args[0];
      final n = asNumber(v);
      if (n != null) return PyFloat(n.toDouble());
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        if (parsed == null) {
          throw PyError(line, 'ValueError', 'float() kann ${pyRepr(v)} nicht in eine Kommazahl umwandeln.');
        }
        return PyFloat(parsed);
      }
      throw _type(line, 'float() kann ${_t(v)} nicht umwandeln.');
    case 'repr':
      _argCount(name, args, 1, 1, line);
      return pyRepr(args[0]);
    case 'ord':
      _argCount(name, args, 1, 1, line);
      final c = args[0];
      if (c is! String || c.runes.length != 1) throw _type(line, 'ord() braucht genau ein Zeichen, z. B. ord("A").');
      return c.runes.first;
    case 'chr':
      _argCount(name, args, 1, 1, line);
      return String.fromCharCode(_asInt(args[0], 'Der Wert für chr()', line));
    case 'bool':
      _argCount(name, args, 0, 1, line);
      return args.isNotEmpty && pyTruthy(args[0]);
    case 'type':
      _argCount(name, args, 1, 1, line);
      return PyType(pyTypeName(args[0]));
    case 'range':
      _argCount(name, args, 1, 3, line);
      final ints = [for (final a in args) _asInt(a, 'Der Wert in range()', line)];
      final r = switch (ints.length) {
        1 => PyRange(0, ints[0], 1),
        2 => PyRange(ints[0], ints[1], 1),
        _ => PyRange(ints[0], ints[1], ints[2]),
      };
      if (r.step == 0) throw PyError(line, 'ValueError', 'Die Schrittweite von range() darf nicht 0 sein.');
      return r;
    case 'list':
      _argCount(name, args, 0, 1, line);
      return PyList(args.isEmpty ? [] : pyIterate(args[0], line).toList());
    case 'tuple':
      _argCount(name, args, 0, 1, line);
      return PyTuple(args.isEmpty ? [] : pyIterate(args[0], line).toList());
    case 'set':
      _argCount(name, args, 0, 1, line);
      final items = args.isEmpty ? <Object?>[] : pyIterate(args[0], line).toList();
      for (final i in items) {
        if (!isHashable(i)) throw _type(line, '${_t(i)} kann nicht in einem Set stehen.');
      }
      return PySet(items);
    case 'dict':
      final d = PyDict();
      if (args.isNotEmpty) {
        for (final pair in pyIterate(args[0], line)) {
          final p = pyIterate(pair, line).toList();
          d.map[p[0]] = p[1];
        }
      }
      d.map.addAll(kwargs);
      return d;
    case 'abs':
      _argCount(name, args, 1, 1, line);
      final n = asNumber(args[0]);
      if (n == null) throw _type(line, 'abs() braucht eine Zahl, nicht ${_t(args[0])}.');
      return Ops.number(n.abs());
    case 'min' || 'max':
      if (args.isEmpty) throw _type(line, '$name() braucht mindestens einen Wert.');
      final items = args.length == 1 ? pyIterate(args[0], line).toList() : args;
      if (items.isEmpty) throw PyError(line, 'ValueError', '$name() von einer leeren Sammlung geht nicht.');
      var best = items.first;
      for (final v in items.skip(1)) {
        final c = Ops.order(v, best, line);
        if (name == 'min' ? c < 0 : c > 0) best = v;
      }
      return best;
    case 'sum':
      _argCount(name, args, 1, 2, line);
      Object? total = args.length > 1 ? args[1] : 0;
      for (final v in pyIterate(args[0], line)) {
        total = Ops.binary('+', total, v, line);
      }
      return total;
    case 'round':
      _argCount(name, args, 1, 2, line);
      final n = asNumber(args[0]);
      if (n == null) throw _type(line, 'round() braucht eine Zahl, nicht ${_t(args[0])}.');
      if (args.length == 1 || args[1] == null) return _roundHalfEven(n.toDouble());
      final digits = _asInt(args[1], 'Die Anzahl Nachkommastellen', line);
      final factor = _pow10(digits);
      final rounded = _roundHalfEven(n * factor) / factor;
      return args[0] is int ? rounded.round() : PyFloat(rounded);
    case 'sorted':
      _argCount(name, args, 1, 1, line);
      final items = pyIterate(args[0], line).toList();
      _sort(items, kwargs, line, ctx);
      return PyList(items);
    case 'reversed':
      _argCount(name, args, 1, 1, line);
      return PyIterator(pyIterate(args[0], line).toList().reversed, 'list_reverseiterator');
    case 'enumerate':
      _argCount(name, args, 1, 2, line);
      var i = args.length > 1 ? _asInt(args[1], 'Der Startwert', line) : _asInt(kwargs['start'] ?? 0, 'Der Startwert', line);
      return PyIterator(pyIterate(args[0], line).map((v) => PyTuple([i++, v])), 'enumerate');
    case 'zip':
      final lists = [for (final a in args) pyIterate(a, line).toList()];
      final n = lists.isEmpty ? 0 : lists.map((l) => l.length).reduce((a, b) => a < b ? a : b);
      return PyIterator([for (var i = 0; i < n; i++) PyTuple([for (final l in lists) l[i]])], 'zip');
    case 'iter':
      _argCount(name, args, 1, 1, line);
      if (args[0] is PyIterator) return args[0];
      final source = args[0];
      final typeName = switch (source) {
        String _ => 'str_ascii_iterator',
        PyTuple _ => 'tuple_iterator',
        PyDict _ => 'dict_keyiterator',
        PySet _ => 'set_iterator',
        PyRange _ => 'range_iterator',
        _ => 'list_iterator',
      };
      return PyIterator(pyIterate(source, line), typeName);
    case 'next':
      _argCount(name, args, 1, 2, line);
      final it = args[0];
      if (it is! PyIterator) {
        throw _type(line, '${_t(it)} ist kein Iterator. Erstelle zuerst einen mit iter(...).');
      }
      final v = it.next();
      if (identical(v, PyIterator.exhausted)) {
        if (args.length > 1) return args[1];
        throw PyError(line, 'StopIteration', 'Der Iterator hat keine Elemente mehr – alle wurden schon mit next() geholt.');
      }
      return v;
    case 'isinstance':
      _argCount(name, args, 2, 2, line);
      final kinds = args[1] is PyTuple ? (args[1] as PyTuple).items : [args[1]];
      for (final k in kinds) {
        final typeName = k is PyBuiltin && _typeFunctions.contains(k.name) ? k.name : (k is PyType ? k.name : null);
        if (typeName == null) throw _type(line, 'Das zweite Argument von isinstance() muss ein Typ sein, z. B. int.');
        final actual = pyTypeName(args[0]);
        if (actual == typeName || (typeName == 'int' && actual == 'bool')) return true;
      }
      return false;
    case 'map':
      _argCount(name, args, 2, 2, line);
      return PyIterator(pyIterate(args[1], line).map((v) => ctx.callValue(args[0], [v], line)), 'map');
    case 'filter':
      _argCount(name, args, 2, 2, line);
      return PyIterator(
          pyIterate(args[1], line).where((v) => pyTruthy(args[0] == null ? v : ctx.callValue(args[0], [v], line))),
          'filter');
    case 'input':
      throw PyError(line, 'Hinweis', 'input() gibt es in diesem Spiel nicht – hier tippt niemand etwas ein. Gib der Variablen direkt einen Wert.');
  }
  throw PyError(line, 'NameError', 'Die Funktion $name() gibt es nicht.');
}

void _sort(List<Object?> items, Map<String, Object?> kwargs, int line, PyContext ctx) {
  final key = kwargs['key'];
  final reverse = pyTruthy(kwargs['reverse']);
  final keys = {for (final v in items) v: key == null ? v : ctx.callValue(key, [v], line)};
  Object? k(Object? v) => key == null ? v : keys[v];
  // stabile Sortierung
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final c = Ops.order(k(a.$2), k(b.$2), line);
    return c != 0 ? (reverse ? -c : c) : a.$1.compareTo(b.$1);
  });
  items
    ..clear()
    ..addAll(indexed.map((e) => e.$2));
}

/// Für list.sort().
void sortInPlace(List<Object?> items, Map<String, Object?> kwargs, int line, PyContext ctx) =>
    _sort(items, kwargs, line, ctx);

double _pow10(int n) {
  var r = 1.0;
  for (var i = 0; i < n.abs(); i++) {
    r *= 10;
  }
  return n < 0 ? 1 / r : r;
}

/// Python rundet "auf die gerade Zahl": round(2.5) == 2, round(3.5) == 4.
int _roundHalfEven(double x) {
  final floor = x.floorToDouble();
  final diff = x - floor;
  if ((diff - 0.5).abs() < 1e-9) return floor.toInt().isEven ? floor.toInt() : floor.toInt() + 1;
  return x.round();
}

/// Formatierung wie in f"{wert:spec}" und "{:spec}".format(wert).
String formatValue(Object? value, String? spec, int line) {
  if (spec == null || spec.isEmpty) return pyStr(value);
  final m = RegExp(r'^([<>^])?(\d+)?(,)?(?:\.(\d+))?([dfs%])?$').firstMatch(spec);
  if (m == null) {
    throw PyError(line, 'ValueError', 'Das Format ":$spec" kennt dieses Spiel nicht. Probiere z. B. :.2f');
  }
  final align = m[1];
  final width = int.tryParse(m[2] ?? '');
  final comma = m[3] != null;
  final precision = int.tryParse(m[4] ?? '');
  final kind = m[5];
  var text = pyStr(value);
  final n = asNumber(value);
  if (kind == 'f' || kind == '%' || (precision != null && n != null)) {
    if (n == null) throw PyError(line, 'ValueError', 'Das Format ":$spec" passt nur zu Zahlen.');
    final shown = kind == '%' ? n * 100 : n;
    text = shown.toDouble().toStringAsFixed(precision ?? 6);
    if (kind == '%') text += '%';
  } else if (kind == 'd') {
    if (value is! int) throw PyError(line, 'ValueError', 'Das Format ":d" passt nur zu ganzen Zahlen.');
  }
  if (comma && n != null) {
    final parts = text.split('.');
    final digits = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (x) => '${x[1]},');
    text = parts.length > 1 ? '$digits.${parts[1]}' : digits;
  }
  if (width != null && text.length < width) {
    final pad = width - text.length;
    final a = align ?? (n != null ? '>' : '<');
    text = switch (a) {
      '>' => ' ' * pad + text,
      '^' => ' ' * (pad ~/ 2) + text + ' ' * (pad - pad ~/ 2),
      _ => text + ' ' * pad,
    };
  }
  return text;
}
