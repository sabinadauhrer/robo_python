import 'dart:math' as math;

import 'builtins.dart';
import 'operators.dart';
import 'py_error.dart';
import 'values.dart';

/// Module, die man mit `import` laden kann.
const moduleNames = {'math', 'json', 'datetime', 're', 'os', 'os.path'};

PyError _type(int line, String message) => PyError(line, 'TypeError', message);

double _num(Object? v, String fn, int line) {
  final n = asNumber(v);
  if (n == null) throw _type(line, '$fn() braucht eine Zahl, nicht ${pyTypeName(v)}.');
  return n.toDouble();
}

int _int(Object? v, String fn, int line) {
  if (v is int) return v;
  if (v is bool) return v ? 1 : 0;
  if (v is PyFloat && v.value == v.value.truncateToDouble()) return v.value.toInt();
  throw _type(line, '$fn() braucht eine ganze Zahl, nicht ${pyTypeName(v)}.');
}

void _count(String fn, List<Object?> args, int min, int max, int line) {
  if (args.length < min || args.length > max) {
    final expected = min == max ? '$min' : '$min bis $max';
    throw _type(line, '$fn() braucht $expected Wert(e) in den Klammern, bekommen hat es ${args.length}.');
  }
}

PyNative _fn(String name, Object? Function(List<Object?> a, Map<String, Object?> k, int line) fn) => PyNative(name, fn);

/// Erstellt ein Modul. [files] ist das virtuelle Dateisystem (für os).
PyModule? createModule(String name, Map<String, String> files) => switch (name) {
  'math' => _math(),
  'json' => _json(),
  'datetime' => _datetime(),
  're' => _re(),
  'os' => PyModule('os', {
    'remove': _fn('remove', (a, k, line) {
      _count('os.remove', a, 1, 1, line);
      final file = a[0];
      if (file is! String) throw _type(line, 'os.remove() braucht einen Dateinamen.');
      if (files.remove(file) == null) {
        throw PyError(line, 'FileNotFoundError', 'Die Datei "$file" gibt es nicht.');
      }
      return null;
    }),
    'path': _osPath(files),
    'listdir': _fn('listdir', (a, k, line) => PyList(files.keys.toList()..sort())),
  }),
  'os.path' => _osPath(files),
  _ => null,
};

PyModule _osPath(Map<String, String> files) => PyModule('os.path', {
  'exists': _fn('exists', (a, k, line) {
    _count('os.path.exists', a, 1, 1, line);
    return files.containsKey(a[0]);
  }),
});

// ---------------------------------------------------------------- math

PyModule _math() {
  PyNative one(String name, double Function(double) f) => _fn(name, (a, k, line) {
    _count('math.$name', a, 1, 1, line);
    return PyFloat(f(_num(a[0], 'math.$name', line)));
  });
  PyNative toInt(String name, num Function(double) f) => _fn(name, (a, k, line) {
    _count('math.$name', a, 1, 1, line);
    final v = a[0];
    if (v is int) return v;
    return f(_num(v, 'math.$name', line)).toInt();
  });
  return PyModule('math', {
    'pi': const PyFloat(math.pi),
    'e': const PyFloat(math.e),
    'tau': const PyFloat(2 * math.pi),
    'inf': const PyFloat(double.infinity),
    'sqrt': _fn('sqrt', (a, k, line) {
      _count('math.sqrt', a, 1, 1, line);
      final x = _num(a[0], 'math.sqrt', line);
      if (x < 0) throw PyError(line, 'ValueError', 'Aus einer negativen Zahl kann man keine Wurzel ziehen.');
      return PyFloat(math.sqrt(x));
    }),
    'ceil': toInt('ceil', (x) => x.ceil()),
    'floor': toInt('floor', (x) => x.floor()),
    'trunc': toInt('trunc', (x) => x.truncate()),
    'fabs': one('fabs', (x) => x.abs()),
    'sin': one('sin', math.sin),
    'cos': one('cos', math.cos),
    'tan': one('tan', math.tan),
    'exp': one('exp', math.exp),
    'log10': one('log10', (x) => math.log(x) / math.ln10),
    'log2': one('log2', (x) => math.log(x) / math.ln2),
    'radians': one('radians', (x) => x * math.pi / 180),
    'degrees': one('degrees', (x) => x * 180 / math.pi),
    'log': _fn('log', (a, k, line) {
      _count('math.log', a, 1, 2, line);
      final x = _num(a[0], 'math.log', line);
      if (x <= 0) throw PyError(line, 'ValueError', 'Den Logarithmus gibt es nur für Zahlen größer als 0.');
      return PyFloat(a.length == 1 ? math.log(x) : math.log(x) / math.log(_num(a[1], 'math.log', line)));
    }),
    'pow': _fn('pow', (a, k, line) {
      _count('math.pow', a, 2, 2, line);
      return PyFloat(math.pow(_num(a[0], 'math.pow', line), _num(a[1], 'math.pow', line)).toDouble());
    }),
    'factorial': _fn('factorial', (a, k, line) {
      _count('math.factorial', a, 1, 1, line);
      final n = _int(a[0], 'math.factorial', line);
      if (n < 0) throw PyError(line, 'ValueError', 'Die Fakultät gibt es nur für Zahlen ab 0.');
      var r = 1;
      for (var i = 2; i <= n; i++) {
        r *= i;
      }
      return r;
    }),
    'gcd': _fn('gcd', (a, k, line) {
      var r = 0;
      for (final v in a) {
        var x = _int(v, 'math.gcd', line).abs();
        var y = r;
        while (y != 0) {
          final t = x % y;
          x = y;
          y = t;
        }
        r = x;
      }
      return r;
    }),
    'isqrt': _fn('isqrt', (a, k, line) {
      _count('math.isqrt', a, 1, 1, line);
      return math.sqrt(_int(a[0], 'math.isqrt', line)).floor();
    }),
    'prod': _fn('prod', (a, k, line) {
      _count('math.prod', a, 1, 1, line);
      Object? r = 1;
      for (final v in pyIterate(a[0], line)) {
        r = Ops.binary('*', r, v, line);
      }
      return r;
    }),
    'isclose': _fn('isclose', (a, k, line) {
      _count('math.isclose', a, 2, 2, line);
      final x = _num(a[0], 'math.isclose', line);
      final y = _num(a[1], 'math.isclose', line);
      return (x - y).abs() <= math.max(1e-09 * math.max(x.abs(), y.abs()), 0.0);
    }),
  });
}

// ---------------------------------------------------------------- json

PyModule _json() => PyModule('json', {
  'dumps': _fn('dumps', (a, k, line) {
    _count('json.dumps', a, 1, 1, line);
    final indentArg = k['indent'];
    final String? indent = switch (indentArg) {
      null => null,
      int n => ' ' * n,
      String s => s,
      _ => throw _type(line, 'indent muss eine Zahl sein.'),
    };
    final seps = k['separators'];
    var itemSep = indent == null ? ', ' : ',';
    var keySep = ': ';
    if (seps != null) {
      final p = pyIterate(seps, line).toList();
      itemSep = p[0] as String;
      keySep = p[1] as String;
    }
    return _JsonWriter(indent, itemSep, keySep, pyTruthy(k['sort_keys']), k['ensure_ascii'] != false, line).write(a[0]);
  }),
  'loads': _fn('loads', (a, k, line) {
    _count('json.loads', a, 1, 1, line);
    final s = a[0];
    if (s is! String) throw _type(line, 'json.loads() braucht einen Text (String).');
    return _JsonReader(s, line).read();
  }),
});

class _JsonWriter {
  _JsonWriter(this.indent, this.itemSep, this.keySep, this.sortKeys, this.ensureAscii, this.line);
  final String? indent;
  final String itemSep;
  final String keySep;
  final bool sortKeys;
  final bool ensureAscii;
  final int line;

  String write(Object? v, [int level = 0]) => switch (v) {
    null => 'null',
    true => 'true',
    false => 'false',
    int i => '$i',
    PyFloat f => f.value.isNaN ? 'NaN' : (f.value.isInfinite ? (f.value > 0 ? 'Infinity' : '-Infinity') : formatFloat(f.value)),
    String s => _string(s),
    PyList l => _array(l.items, level),
    PyTuple t => _array(t.items, level),
    PyDict d => _object(d, level),
    _ => throw _type(line, 'Ein Wert vom Typ ${pyTypeName(v)} kann nicht in JSON umgewandelt werden.'),
  };

  String _string(String s) {
    final b = StringBuffer('"');
    for (final r in s.runes) {
      switch (r) {
        case 0x22:
          b.write(r'\"');
        case 0x5C:
          b.write(r'\\');
        case 0x0A:
          b.write(r'\n');
        case 0x0D:
          b.write(r'\r');
        case 0x09:
          b.write(r'\t');
        default:
          if (r < 0x20 || (ensureAscii && r > 0x7E)) {
            if (r > 0xFFFF) {
              final v = r - 0x10000;
              b.write('\\u${(0xD800 + (v >> 10)).toRadixString(16).padLeft(4, '0')}');
              b.write('\\u${(0xDC00 + (v & 0x3FF)).toRadixString(16).padLeft(4, '0')}');
            } else {
              b.write('\\u${r.toRadixString(16).padLeft(4, '0')}');
            }
          } else {
            b.writeCharCode(r);
          }
      }
    }
    b.write('"');
    return b.toString();
  }

  String _join(List<String> parts, int level, String open, String close) {
    if (parts.isEmpty) return '$open$close';
    if (indent == null) return '$open${parts.join(itemSep)}$close';
    final inner = '\n${indent! * (level + 1)}';
    return '$open$inner${parts.join('$itemSep$inner')}\n${indent! * level}$close';
  }

  String _array(List<Object?> items, int level) => _join([for (final i in items) write(i, level + 1)], level, '[', ']');

  String _object(PyDict d, int level) {
    final entries = d.map.entries.toList();
    if (sortKeys) entries.sort((a, b) => Ops.order(a.key, b.key, line));
    return _join([
      for (final e in entries) '${_string(_key(e.key))}$keySep${write(e.value, level + 1)}',
    ], level, '{', '}');
  }

  String _key(Object? k) => switch (k) {
    String s => s,
    null => 'null',
    true => 'true',
    false => 'false',
    int i => '$i',
    PyFloat f => formatFloat(f.value),
    _ => throw _type(line, 'Schlüssel in JSON müssen Texte oder Zahlen sein.'),
  };
}

class _JsonReader {
  _JsonReader(this.s, this.line);
  final String s;
  final int line;
  int i = 0;

  PyError _error() => PyError(line, 'JSONDecodeError', 'Der Text ist kein gültiges JSON (Stelle ${i + 1}).');

  void _ws() {
    while (i < s.length && ' \t\n\r'.contains(s[i])) {
      i++;
    }
  }

  Object? read() {
    final v = _value();
    _ws();
    if (i != s.length) throw _error();
    return v;
  }

  Object? _value() {
    _ws();
    if (i >= s.length) throw _error();
    final c = s[i];
    if (c == '{') {
      i++;
      final d = PyDict();
      _ws();
      if (i < s.length && s[i] == '}') {
        i++;
        return d;
      }
      while (true) {
        _ws();
        if (i >= s.length || s[i] != '"') throw _error();
        final key = _string();
        _ws();
        if (i >= s.length || s[i] != ':') throw _error();
        i++;
        d.map[key] = _value();
        _ws();
        if (i < s.length && s[i] == ',') {
          i++;
          continue;
        }
        if (i < s.length && s[i] == '}') {
          i++;
          return d;
        }
        throw _error();
      }
    }
    if (c == '[') {
      i++;
      final l = PyList();
      _ws();
      if (i < s.length && s[i] == ']') {
        i++;
        return l;
      }
      while (true) {
        l.items.add(_value());
        _ws();
        if (i < s.length && s[i] == ',') {
          i++;
          continue;
        }
        if (i < s.length && s[i] == ']') {
          i++;
          return l;
        }
        throw _error();
      }
    }
    if (c == '"') return _string();
    for (final (word, value) in const [('true', true), ('false', false), ('null', null)]) {
      if (s.startsWith(word, i)) {
        i += word.length;
        return value;
      }
    }
    final m = RegExp(r'-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?').matchAsPrefix(s, i);
    if (m == null || m[0]!.isEmpty) throw _error();
    i = m.end;
    if (m[2] == null && m[3] == null) return int.parse(m[0]!);
    return PyFloat(double.parse(m[0]!));
  }

  String _string() {
    i++; // "
    final b = StringBuffer();
    while (i < s.length) {
      final c = s[i];
      if (c == '"') {
        i++;
        return b.toString();
      }
      if (c == '\\' && i + 1 < s.length) {
        final n = s[i + 1];
        i += 2;
        switch (n) {
          case 'n':
            b.write('\n');
          case 't':
            b.write('\t');
          case 'r':
            b.write('\r');
          case 'b':
            b.write('\b');
          case 'f':
            b.write('\f');
          case 'u':
            if (i + 4 > s.length) throw _error();
            b.writeCharCode(int.parse(s.substring(i, i + 4), radix: 16));
            i += 4;
          default:
            b.write(n);
        }
        continue;
      }
      b.write(c);
      i++;
    }
    throw _error();
  }
}

// ---------------------------------------------------------------- datetime

PyModule _datetime() {
  DateTime build(List<Object?> a, Map<String, Object?> k, int line, String fn, {required bool dateOnly}) {
    final names = dateOnly ? ['year', 'month', 'day'] : ['year', 'month', 'day', 'hour', 'minute', 'second', 'microsecond'];
    if (a.length < 3 && !k.containsKey('day')) {
      throw _type(line, '$fn() braucht mindestens Jahr, Monat und Tag, z. B. $fn(2025, 3, 14).');
    }
    final v = <int>[];
    for (var i = 0; i < names.length; i++) {
      final x = i < a.length ? a[i] : (k[names[i]] ?? 0);
      v.add(_int(x, fn, line));
    }
    if (v[1] < 1 || v[1] > 12) throw PyError(line, 'ValueError', 'Den Monat ${v[1]} gibt es nicht (1 bis 12).');
    final result = DateTime(v[0], v[1], v[2], dateOnly ? 0 : v[3], dateOnly ? 0 : v[4], dateOnly ? 0 : v[5], 0,
        dateOnly ? 0 : v[6]);
    if (result.day != v[2]) throw PyError(line, 'ValueError', 'Den Tag ${v[2]} gibt es in diesem Monat nicht.');
    return result;
  }

  final datetimeClass = PyNative(
    'datetime',
    (a, k, line) => PyDateTime(build(a, k, line, 'datetime.datetime', dateOnly: false)),
    typeLabel: 'type',
    attrs: {
      'now': _fn('now', (a, k, line) => PyDateTime(DateTime.now())),
      'today': _fn('today', (a, k, line) => PyDateTime(DateTime.now())),
    },
  );
  final dateClass = PyNative(
    'date',
    (a, k, line) => PyDateTime(build(a, k, line, 'datetime.date', dateOnly: true), dateOnly: true),
    typeLabel: 'type',
    attrs: {
      'today': _fn('today', (a, k, line) {
        final n = DateTime.now();
        return PyDateTime(DateTime(n.year, n.month, n.day), dateOnly: true);
      }),
    },
  );
  return PyModule('datetime', {'datetime': datetimeClass, 'date': dateClass});
}

// ---------------------------------------------------------------- re

PyModule _re() {
  RegExp compile(Object? pattern, int line, [Object? flags]) {
    if (pattern is! String) throw _type(line, 'Das Suchmuster muss ein Text sein.');
    final f = flags is int ? flags : 0;
    try {
      return RegExp(pattern.replaceAll('(?P<', '(?<').replaceAll(r'\Z', r'$'),
          caseSensitive: f & 2 == 0, multiLine: f & 8 != 0, dotAll: f & 16 != 0, unicode: true);
    } on FormatException {
      throw PyError(line, 'error', 'Das Suchmuster ${pyRepr(pattern)} ist ungültig.');
    }
  }

  String text(Object? v, int line) {
    if (v is String) return v;
    throw _type(line, 'Der durchsuchte Text muss ein String sein.');
  }

  Object? flags(List<Object?> a, Map<String, Object?> k, int index) => a.length > index ? a[index] : k['flags'];

  return PyModule('re', {
    'IGNORECASE': 2,
    'I': 2,
    'MULTILINE': 8,
    'M': 8,
    'DOTALL': 16,
    'S': 16,
    'findall': _fn('findall', (a, k, line) {
      _count('re.findall', a, 2, 3, line);
      final re = compile(a[0], line, flags(a, k, 2));
      final s = text(a[1], line);
      return PyList([
        for (final m in re.allMatches(s))
          if (m.groupCount == 0)
            m[0]
          else if (m.groupCount == 1)
            m[1] ?? ''
          else
            PyTuple([for (var g = 1; g <= m.groupCount; g++) m[g] ?? '']),
      ]);
    }),
    'search': _fn('search', (a, k, line) {
      _count('re.search', a, 2, 3, line);
      final s = text(a[1], line);
      final m = compile(a[0], line, flags(a, k, 2)).firstMatch(s);
      return m == null ? null : PyReMatch(m, s);
    }),
    'match': _fn('match', (a, k, line) {
      _count('re.match', a, 2, 3, line);
      final s = text(a[1], line);
      final m = compile(a[0], line, flags(a, k, 2)).matchAsPrefix(s);
      return m == null ? null : PyReMatch(m as RegExpMatch, s);
    }),
    'fullmatch': _fn('fullmatch', (a, k, line) {
      _count('re.fullmatch', a, 2, 3, line);
      final s = text(a[1], line);
      final m = compile('(?:${a[0]})\$', line, flags(a, k, 2)).matchAsPrefix(s);
      return m == null ? null : PyReMatch(m as RegExpMatch, s);
    }),
    'split': _fn('split', (a, k, line) {
      _count('re.split', a, 2, 3, line);
      final re = compile(a[0], line, k['flags']);
      final s = text(a[1], line);
      final max = a.length > 2 ? _int(a[2], 're.split', line) : (k['maxsplit'] is int ? k['maxsplit'] as int : 0);
      final parts = <Object?>[];
      var last = 0;
      var n = 0;
      for (final m in re.allMatches(s)) {
        if (max > 0 && n >= max) break;
        if (m.end == m.start && m.start == last && last != 0) continue;
        parts.add(s.substring(last, m.start));
        for (var g = 1; g <= m.groupCount; g++) {
          parts.add(m[g]);
        }
        last = m.end;
        n++;
      }
      parts.add(s.substring(last));
      return PyList(parts);
    }),
    'sub': _fn('sub', (a, k, line) {
      _count('re.sub', a, 3, 4, line);
      final re = compile(a[0], line, k['flags']);
      final repl = a[1];
      final s = text(a[2], line);
      final count = a.length > 3 ? _int(a[3], 're.sub', line) : (k['count'] is int ? k['count'] as int : 0);
      var n = 0;
      return s.replaceAllMapped(re, (m) {
        if (count > 0 && n >= count) return m[0]!;
        n++;
        if (repl is String) {
          return repl.replaceAllMapped(RegExp(r'\\(\d+)|\\g<(\w+)>'), (r) {
            final g = r[1] ?? r[2]!;
            final i = int.tryParse(g);
            return (i != null ? m.group(i) : (m as RegExpMatch).namedGroup(g)) ?? '';
          });
        }
        return pyStr(activeContext!.callValue(repl, [PyReMatch(m as RegExpMatch, s)], line));
      });
    }),
  });
}
