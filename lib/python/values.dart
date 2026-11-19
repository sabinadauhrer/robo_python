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
  PySet([Iterable<Object?> items = const [], this.frozen = false])
    : items = LinkedHashSet(equals: pyEquals, hashCode: pyHash)..addAll(items);
  final LinkedHashSet<Object?> items;

  /// frozenset: unveränderlich.
  final bool frozen;
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
    this.enclosing,
    this.localNames = const {},
    this.varArgs,
    this.kwArgs,
    this.positionalOnly = 0,
    this.keywordOnly = const {},
    this.isGenerator = false,
    this.ownerClass,
  });

  /// Namen, denen die Funktion etwas zuweist – sie sind lokal (wie in Python).
  final Set<String> localNames;

  /// Name für *args bzw. **kwargs (falls vorhanden).
  final String? varArgs;
  final String? kwArgs;

  /// Anzahl Parameter vor einem "/" (nur per Position übergebbar).
  final int positionalOnly;

  /// Parameter nach einem "*" (nur per Name übergebbar).
  final Set<String> keywordOnly;

  /// Enthält yield → Aufruf liefert einen Generator.
  final bool isGenerator;

  /// Klasse, in der die Methode definiert wurde (für super() und __privat).
  PyClass? ownerClass;

  /// Funktion, in der diese Funktion definiert wurde (für verschachtelte Funktionen).
  final PyFunction? enclosing;

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

/// Eine Klasse (Bauplan für Objekte).
class PyClass {
  PyClass(this.name, this.bases, [Map<String, Object?>? attrs, this.builtin = false]) : attrs = attrs ?? {};
  final String name;
  final List<PyClass> bases;
  final Map<String, Object?> attrs;

  /// Eingebaute Klasse wie Exception oder object.
  final bool builtin;

  /// Reihenfolge, in der Attribute gesucht werden: die Klasse selbst, dann die Elternklassen.
  late final List<PyClass> mro = () {
    final result = <PyClass>[this];
    for (final b in bases) {
      for (final c in b.mro) {
        result.remove(c);
        result.add(c);
      }
    }
    return result;
  }();

  bool isSubclassOf(PyClass other) => mro.contains(other);

  /// Sucht ein Attribut in der Klasse und ihren Elternklassen.
  (bool, Object?) find(String name) {
    for (final c in mro) {
      if (c.attrs.containsKey(name)) return (true, c.attrs[name]);
    }
    return (false, null);
  }

  bool get isException => mro.any((c) => c.name == 'BaseException' && c.builtin);
}

/// Ein Objekt einer Klasse.
class PyInstance {
  PyInstance(this.cls);
  final PyClass cls;
  final attrs = <String, Object?>{};
}

/// Methode, die schon mit ihrem Objekt (self) verbunden ist.
class PyBoundMethod {
  const PyBoundMethod(this.self, this.function);
  final Object? self;
  final Object? function;
}

/// Ergebnis von super(): sucht Methoden ab der Elternklasse.
class PySuper {
  const PySuper(this.start, this.self);
  final PyClass start;
  final Object? self;
}

/// Ein Modul wie math oder json.
class PyModule {
  PyModule(this.name, this.attrs);
  final String name;
  final Map<String, Object?> attrs;
}

/// In Dart geschriebene Funktion (z. B. math.sqrt).
class PyNative {
  PyNative(this.name, this.fn, {Map<String, Object?>? attrs, this.typeLabel = 'builtin_function_or_method'})
    : attrs = attrs ?? {};
  final String name;
  final Object? Function(List<Object?> args, Map<String, Object?> kwargs, int line) fn;

  /// Attribute, z. B. datetime.datetime.now
  final Map<String, Object?> attrs;
  final String typeLabel;
}

/// datetime.datetime bzw. datetime.date
class PyDateTime {
  const PyDateTime(this.value, {this.dateOnly = false});
  final DateTime value;
  final bool dateOnly;

  @override
  bool operator ==(Object other) => other is PyDateTime && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Eine (virtuelle) Datei, geöffnet mit open().
class PyFile {
  PyFile(this.name, this.mode, this.files) {
    if (mode.contains('w')) files[name] = '';
    _content = files[name] ?? '';
  }
  final String name;
  final String mode;
  final Map<String, String> files;
  late String _content;
  int position = 0;
  bool closed = false;

  bool get readable => mode.contains('r') || mode.contains('+');
  String get content => _content;

  void write(String s) {
    files[name] = (files[name] ?? '') + s;
    _content = files[name]!;
  }
}

/// Ergebnis von re.search() / re.match().
class PyReMatch {
  const PyReMatch(this.match, this.string);
  final RegExpMatch match;
  final String string;
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
  PySet s => s.frozen,
  PyList() || PyDict() => false,
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
  PyDictView v => v.items.isNotEmpty,
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
  PySet s => s.frozen ? 'frozenset' : 'set',
  PyRange _ => 'range',
  PyDictView d => 'dict_${d.kind.label}',
  PyIterator i => i.typeName,
  PyFunction _ => 'function',
  PyBoundMethod _ => 'method',
  PyBuiltin _ => 'builtin_function_or_method',
  PyNative n => n.typeLabel,
  PyType _ || PyClass _ => 'type',
  PyInstance i => i.cls.name,
  PyModule _ => 'module',
  PyDateTime d => d.dateOnly ? 'date' : 'datetime',
  PyFile _ => 'TextIOWrapper',
  PyReMatch _ => 'Match',
  PySuper _ => 'super',
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
  PySet s => s.frozen ? 'Feste Menge (frozenset)' : 'Menge (set)',
  PyRange _ => 'Bereich (range)',
  PyFunction _ => 'Funktion',
  PyBoundMethod _ => 'Methode',
  PyIterator i => i.typeName == 'generator' ? 'Generator' : 'Iterator',
  PyClass c => c.isException ? 'Fehler-Klasse' : 'Klasse',
  PyInstance i => i.cls.isException ? 'Fehler (${i.cls.name})' : 'Objekt (${i.cls.name})',
  PyModule _ => 'Modul',
  PyDateTime d => d.dateOnly ? 'Datum (date)' : 'Zeitpunkt (datetime)',
  PyFile _ => 'Datei',
  PyReMatch _ => 'Treffer (Match)',
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

/// Ruft __str__ bzw. __repr__ eigener Klassen auf (vom Interpreter gesetzt).
/// Liefert null, wenn die Klasse keine eigene Darstellung hat.
String? Function(PyInstance instance, bool repr)? instanceToString;

String _two(int n) => n.toString().padLeft(2, '0');

String dateTimeStr(PyDateTime d) {
  final v = d.value;
  final date = '${v.year.toString().padLeft(4, '0')}-${_two(v.month)}-${_two(v.day)}';
  if (d.dateOnly) return date;
  final micro = v.millisecond * 1000 + v.microsecond;
  return '$date ${_two(v.hour)}:${_two(v.minute)}:${_two(v.second)}${micro == 0 ? '' : '.${micro.toString().padLeft(6, '0')}'}';
}

String _dateTimeRepr(PyDateTime d) {
  final v = d.value;
  if (d.dateOnly) return 'datetime.date(${v.year}, ${v.month}, ${v.day})';
  final parts = [v.year, v.month, v.day, v.hour, v.minute];
  final micro = v.millisecond * 1000 + v.microsecond;
  if (v.second != 0 || micro != 0) parts.add(v.second);
  if (micro != 0) parts.add(micro);
  return 'datetime.datetime(${parts.join(', ')})';
}

String _instanceRepr(PyInstance i) {
  final custom = instanceToString?.call(i, true);
  if (custom != null) return custom;
  if (i.cls.isException) {
    final args = i.attrs['args'];
    final items = args is PyTuple ? args.items : const [];
    return '${i.cls.name}(${items.map(pyRepr).join(', ')})';
  }
  return '<__main__.${i.cls.name} object>';
}

String _instanceStr(PyInstance i) {
  final custom = instanceToString?.call(i, false);
  if (custom != null) return custom;
  if (i.cls.isException) {
    final args = i.attrs['args'];
    final items = args is PyTuple ? args.items : const [];
    if (items.isEmpty) return '';
    if (items.length == 1) return pyStr(items.first);
    return pyRepr(args);
  }
  return _instanceRepr(i);
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
    PySet s when s.frozen => s.items.isEmpty ? 'frozenset()' : 'frozenset({${s.items.map(r).join(', ')}})',
    PySet s => s.items.isEmpty ? 'set()' : '{${s.items.map(r).join(', ')}}',
    PyRange g => g.step == 1 ? 'range(${g.start}, ${g.stop})' : 'range(${g.start}, ${g.stop}, ${g.step})',
    PyDictView dv => 'dict_${dv.kind.label}([${dv.items.map(r).join(', ')}])',
    PyIterator i => '<${i.typeName} object>',
    PyFunction f => f.isLambda ? '<function <lambda>>' : '<function ${f.ownerClass == null ? '' : '${f.ownerClass!.name}.'}${f.name}>',
    PyBoundMethod m => '<bound method ${m.function is PyFunction ? (m.function as PyFunction).name : '?'}>',
    PyBuiltin b => '<built-in function ${b.name}>',
    PyNative n => '<built-in function ${n.name}>',
    PyType t => "<class '${t.name}'>",
    PyClass c => c.builtin ? "<class '${c.name}'>" : "<class '__main__.${c.name}'>",
    PyInstance i => _instanceRepr(i),
    PyModule m => "<module '${m.name}'>",
    PyDateTime d => _dateTimeRepr(d),
    PyFile f => "<_io.TextIOWrapper name='${f.name}' mode='${f.mode}' encoding='UTF-8'>",
    PyReMatch m => "<re.Match object; span=(${m.match.start}, ${m.match.end}), match=${r(m.match[0])}>",
    PySuper _ => '<super object>',
    _ => '$v',
  };
}

/// Darstellung wie bei print() (str): Texte ohne Anführungszeichen.
String pyStr(Object? v) => switch (v) {
  String s => s,
  PyInstance i => _instanceStr(i),
  PyDateTime d => dateTimeStr(d),
  _ => pyRepr(v),
};
