import 'dart:collection';

import 'ast.dart';

// Python-Werte zur Laufzeit:
//   None → null, bool → bool, int → int, str → String,
//   float → PyFloat (eigene Klasse, damit 5.0 auch im Browser eine Kommazahl bleibt),
//   list/tuple/dict/set/range/... → eigene Klassen unten.

class PyFloat {
  const PyFloat(this.value);
  final double value;

  @override
  bool operator ==(Object other) => other is PyFloat && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class PyList {
  PyList([List<Object?>? items]) : items = items ?? [];
  final List<Object?> items;
}

class PyTuple {
  PyTuple(List<Object?> items) : items = List.unmodifiable(items);
  final List<Object?> items;

  @override
  bool operator ==(Object other) => other is PyTuple && pyEquals(this, other);

  @override
  int get hashCode => Object.hashAll(items.map(pyHash));
}

class PyDict {
  PyDict() : map = LinkedHashMap(equals: pyEquals, hashCode: pyHash);
  final LinkedHashMap<Object?, Object?> map;
}

class PySet {
  PySet([Iterable<Object?> items = const []])
    : items = LinkedHashSet(equals: pyEquals, hashCode: pyHash)..addAll(items);
  final LinkedHashSet<Object?> items;
}

class PyRange {
  const PyRange(this.start, this.stop, this.step);
  final int start;
  final int stop;
  final int step;

  Iterable<int> get values sync* {
    for (var v = start; step > 0 ? v < stop : v > stop; v += step) {
      yield v;
    }
  }

  int get length {
    final n = step > 0 ? (stop - start + step - 1) ~/ step : (start - stop - step - 1) ~/ -step;
    return n < 0 ? 0 : n;
  }
}

enum DictViewKind {
  keys('keys'),
  vals('values'),
  items('items');

  const DictViewKind(this.label);
  final String label;
}

/// dict.keys(), dict.values(), dict.items() – "lebendige" Sicht auf das Dictionary.
class PyDictView {
  const PyDictView(this.kind, this.dict);
  final DictViewKind kind;
  final PyDict dict;

  Iterable<Object?> get items => switch (kind) {
    DictViewKind.keys => dict.map.keys,
    DictViewKind.vals => dict.map.values,
    DictViewKind.items => dict.map.entries.map((e) => PyTuple([e.key, e.value])),
  };
}

/// Ergebnis von iter(), enumerate(), zip(), reversed().
class PyIterator {
  PyIterator(Iterable<Object?> source, this.typeName) : _it = source.iterator;
  final Iterator<Object?> _it;
  final String typeName;
  bool _done = false;

  /// Nächstes Element oder [exhausted].
  Object? next() {
    if (_done || !_it.moveNext()) {
      _done = true;
      return exhausted;
    }
    return _it.current;
  }

  static const exhausted = _Exhausted();
}

class _Exhausted {
  const _Exhausted();
}

class PyFunction {
  PyFunction({
    required this.name,
    required this.params,
    required this.defaults,
    required this.line,
    this.body,
    this.lambdaBody,
    this.closure,
    this.localNames = const {},
  });

  /// Namen, denen die Funktion etwas zuweist – sie sind lokal (wie in Python).
  final Set<String> localNames;

  final String name;
  final List<String> params;
  final Map<String, Object?> defaults;
  final int line;
  final List<Stmt>? body;
  final Expr? lambdaBody;

  /// Lokale Variablen der umgebenden Funktion (für lambda in Funktionen).
  final Map<String, Object?>? closure;

  bool get isLambda => lambdaBody != null;
}

/// Eingebaute Funktion wie len() oder print(). Die Ausführung übernimmt der Interpreter.
class PyBuiltin {
  const PyBuiltin(this.name);
  final String name;
}

/// Ergebnis von type(x).
class PyType {
  const PyType(this.name);
  final String name;

  @override
  bool operator ==(Object other) => other is PyType && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

// ---------------- Hilfsfunktionen ----------------

/// Zahlenwert für Rechnungen: bool und int → int, float → double, sonst null.
num? asNumber(Object? v) => switch (v) {
  bool b => b ? 1 : 0,
  int i => i,
  PyFloat f => f.value,
  _ => null,
};

bool isNumber(Object? v) => v is int || v is bool || v is PyFloat;

/// Python-Gleichheit (==), auch 1 == 1.0 und verschachtelte Listen.
bool pyEquals(Object? a, Object? b) {
  if (isNumber(a) && isNumber(b)) return asNumber(a) == asNumber(b);
  if (a is PyList && b is PyList) return _listEquals(a.items, b.items);
  if (a is PyTuple && b is PyTuple) return _listEquals(a.items, b.items);
  if (a is PyDict && b is PyDict) {
    if (a.map.length != b.map.length) return false;
    for (final e in a.map.entries) {
      if (!b.map.containsKey(e.key) || !pyEquals(e.value, b.map[e.key])) return false;
    }
    return true;
  }
  if (a is PySet && b is PySet) {
    return a.items.length == b.items.length && a.items.every(b.items.contains);
  }
  if (a is String && b is String) return a == b;
  if (a == null || b == null) return a == b;
  return identical(a, b) || a == b;
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!pyEquals(a[i], b[i])) return false;
  }
  return true;
}

int pyHash(Object? v) {
  final n = asNumber(v);
  if (n != null) return n == n.truncate() ? n.truncate().hashCode : n.hashCode;
  if (v is PyTuple) return v.hashCode;
  return v.hashCode;
}

bool isHashable(Object? v) => switch (v) {
  PyList() || PyDict() || PySet() => false,
  PyTuple t => t.items.every(isHashable),
  _ => true,
};

bool pyTruthy(Object? v) => switch (v) {
  null => false,
  bool b => b,
  int i => i != 0,
  PyFloat f => f.value != 0,
  String s => s.isNotEmpty,
  PyList l => l.items.isNotEmpty,
  PyTuple t => t.items.isNotEmpty,
  PyDict d => d.map.isNotEmpty,
  PySet s => s.items.isNotEmpty,
  PyRange r => r.length > 0,
  _ => true,
};

/// Python-Typname, z. B. "int" oder "list".
String pyTypeName(Object? v) => switch (v) {
  null => 'NoneType',
  bool _ => 'bool',
  int _ => 'int',
  PyFloat _ => 'float',
  String _ => 'str',
  PyList _ => 'list',
  PyTuple _ => 'tuple',
  PyDict _ => 'dict',
  PySet _ => 'set',
  PyRange _ => 'range',
  PyDictView d => 'dict_${d.kind.label}',
  PyIterator i => i.typeName,
  PyFunction _ => 'function',
  PyBuiltin _ => 'builtin_function_or_method',
  PyType _ => 'type',
  _ => 'object',
};

/// Deutsche Beschreibung des Typs für die Variablen-Kästchen.
String germanTypeName(Object? v) => switch (v) {
  null => 'Nichts (None)',
  bool _ => 'Wahrheitswert (bool)',
  int _ => 'Ganzzahl (int)',
  PyFloat _ => 'Kommazahl (float)',
  String _ => 'Text (str)',
  PyList _ => 'Liste (list)',
  PyTuple _ => 'Tupel (tuple)',
  PyDict _ => 'Dictionary (dict)',
  PySet _ => 'Menge (set)',
  PyRange _ => 'Bereich (range)',
  PyFunction _ => 'Funktion',
  PyIterator _ => 'Iterator',
  _ => pyTypeName(v),
};

String formatFloat(double d) {
  if (d.isNaN) return 'nan';
  if (d.isInfinite) return d > 0 ? 'inf' : '-inf';
  if (d == d.truncateToDouble() && d.abs() < 1e16) {
    final whole = d.truncate();
    return '${whole == 0 && d.isNegative ? '-' : ''}$whole.0';
  }
  var s = d.toString();
  // Dart schreibt 1e-7, Python 1e-07
  s = s.replaceAllMapped(RegExp(r'e([+-]?)(\d)$'), (m) => 'e${m[1] == '' ? '+' : m[1]}0${m[2]}');
  return s;
}

String _quote(String s) {
  final useDouble = s.contains("'") && !s.contains('"');
  final q = useDouble ? '"' : "'";
  final escaped = s
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t')
      .replaceAll(q, '\\$q');
  return '$q$escaped$q';
}

/// Darstellung wie in der Python-Konsole (repr).
String pyRepr(Object? v, [int depth = 0]) {
  if (depth > 20) return '...';
  String r(Object? x) => pyRepr(x, depth + 1);
  return switch (v) {
    null => 'None',
    true => 'True',
    false => 'False',
    int i => '$i',
    PyFloat f => formatFloat(f.value),
    String s => _quote(s),
    PyList l => '[${l.items.map(r).join(', ')}]',
    PyTuple t => t.items.length == 1 ? '(${r(t.items.first)},)' : '(${t.items.map(r).join(', ')})',
    PyDict d => '{${d.map.entries.map((e) => '${r(e.key)}: ${r(e.value)}').join(', ')}}',
    PySet s => s.items.isEmpty ? 'set()' : '{${s.items.map(r).join(', ')}}',
    PyRange g => g.step == 1 ? 'range(${g.start}, ${g.stop})' : 'range(${g.start}, ${g.stop}, ${g.step})',
    PyDictView dv => 'dict_${dv.kind.label}([${dv.items.map(r).join(', ')}])',
    PyIterator i => '<${i.typeName} object>',
    PyFunction f => f.isLambda ? '<function <lambda>>' : '<function ${f.name}>',
    PyBuiltin b => '<built-in function ${b.name}>',
    PyType t => "<class '${t.name}'>",
    _ => '$v',
  };
}

/// Darstellung wie bei print() (str): Texte ohne Anführungszeichen.
String pyStr(Object? v) => v is String ? v : pyRepr(v);
