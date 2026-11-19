import 'builtins.dart';
import 'operators.dart';
import 'py_error.dart';
import 'values.dart';

PyError _type(int line, String message) => PyError(line, 'TypeError', message);

void _args(String name, List<Object?> args, int min, int max, int line) {
  if (args.length < min || args.length > max) {
    final expected = min == max ? (min == 0 ? 'keine Werte' : '$min Wert(e)') : '$min bis $max Werte';
    throw _type(line, '.$name() braucht $expected in den Klammern, bekommen hat es ${args.length}.');
  }
}

String _str(Object? v, String what, int line) {
  if (v is String) return v;
  throw _type(line, '$what muss ein Text sein, nicht ${pyTypeName(v)}.');
}

/// Ruft z. B. text.upper() oder liste.append(4) auf.
Object? callMethod(
  Object? target,
  String name,
  List<Object?> args,
  Map<String, Object?> kwargs,
  int line,
  PyContext ctx,
) {
  final result = switch (target) {
    String s => _stringMethod(s, name, args, kwargs, line),
    PyList l => _listMethod(l, name, args, kwargs, line, ctx),
    PyDict d => _dictMethod(d, name, args, kwargs, line),
    PySet s => _setMethod(s, name, args, line),
    PyTuple t => _tupleMethod(t, name, args, line),
    PyFile f => _fileMethod(f, name, args, line),
    PyDateTime d => _dateMethod(d, name, args, line),
    PyReMatch m => _matchMethod(m, name, args, line),
    _ => _missing,
  };
  if (identical(result, _missing)) {
    throw PyError(line, 'AttributeError',
        '${pyTypeName(target)} (${germanTypeName(target)}) hat keine Methode .$name().');
  }
  return result;
}

const _missing = Object();

Object? _stringMethod(String s, String name, List<Object?> args, Map<String, Object?> kwargs, int line) {
  switch (name) {
    case 'upper':
      _args(name, args, 0, 0, line);
      return s.toUpperCase();
    case 'lower':
      _args(name, args, 0, 0, line);
      return s.toLowerCase();
    case 'strip' || 'lstrip' || 'rstrip':
      _args(name, args, 0, 1, line);
      final chars = args.isEmpty || args[0] == null ? ' \t\n' : _str(args[0], 'Das Argument', line);
      var start = 0;
      var end = s.length;
      if (name != 'rstrip') {
        while (start < end && chars.contains(s[start])) {
          start++;
        }
      }
      if (name != 'lstrip') {
        while (end > start && chars.contains(s[end - 1])) {
          end--;
        }
      }
      return s.substring(start, end);
    case 'replace':
      _args(name, args, 2, 3, line);
      final old = _str(args[0], 'Der gesuchte Text', line);
      final neu = _str(args[1], 'Der neue Text', line);
      if (args.length == 3 && args[2] is int && (args[2] as int) >= 0) {
        var result = s;
        var from = 0;
        for (var k = 0; k < (args[2] as int); k++) {
          final i = result.indexOf(old, from);
          if (i < 0) break;
          result = result.replaceRange(i, i + old.length, neu);
          from = i + neu.length;
        }
        return result;
      }
      return s.replaceAll(old, neu);
    case 'split' || 'rsplit':
      _args(name, args, 0, 2, line);
      final sepArg = args.isNotEmpty ? args[0] : kwargs['sep'];
      final sep = sepArg == null ? null : _str(sepArg, 'Das Trennzeichen', line);
      final maxArg = args.length > 1 ? args[1] : kwargs['maxsplit'];
      final max = maxArg is int ? maxArg : -1;
      if (sep != null && sep.isEmpty) throw PyError(line, 'ValueError', 'Das Trennzeichen darf nicht leer sein.');
      var parts = sep == null ? s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList() : s.split(sep);
      if (max >= 0 && parts.length > max + 1) {
        final joiner = sep ?? ' ';
        parts = name == 'split'
            ? [...parts.take(max), parts.skip(max).join(joiner)]
            : [parts.take(parts.length - max).join(joiner), ...parts.skip(parts.length - max)];
      }
      return PyList(parts);
    case 'splitlines':
      _args(name, args, 0, 0, line);
      final lines = s.split('\n');
      if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
      return PyList(lines);
    case 'partition' || 'rpartition':
      _args(name, args, 1, 1, line);
      final sep = _str(args[0], 'Das Trennzeichen', line);
      final i = name == 'partition' ? s.indexOf(sep) : s.lastIndexOf(sep);
      if (i < 0) return name == 'partition' ? PyTuple([s, '', '']) : PyTuple(['', '', s]);
      return PyTuple([s.substring(0, i), sep, s.substring(i + sep.length)]);
    case 'casefold':
      _args(name, args, 0, 0, line);
      return s.toLowerCase().replaceAll('ß', 'ss');
    case 'swapcase':
      _args(name, args, 0, 0, line);
      return s.split('').map((c) => c == c.toUpperCase() ? c.toLowerCase() : c.toUpperCase()).join();
    case 'center' || 'ljust' || 'rjust':
      _args(name, args, 1, 2, line);
      final width = args[0];
      if (width is! int) throw _type(line, 'Die Breite muss eine ganze Zahl sein.');
      final fill = args.length > 1 ? _str(args[1], 'Das Füllzeichen', line) : ' ';
      final pad = width - s.length;
      if (pad <= 0) return s;
      return switch (name) {
        'ljust' => s + fill * pad,
        'rjust' => fill * pad + s,
        // wie in Python: links = pad // 2 (+1, wenn pad und Breite ungerade sind)
        _ => fill * (pad ~/ 2 + (pad & width & 1)) + s + fill * (pad - (pad ~/ 2 + (pad & width & 1))),
      };
    case 'zfill':
      _args(name, args, 1, 1, line);
      final width = args[0];
      if (width is! int) throw _type(line, 'Die Breite muss eine ganze Zahl sein.');
      if (s.length >= width) return s;
      final signed = s.startsWith('-') || s.startsWith('+');
      final body = signed ? s.substring(1) : s;
      return '${signed ? s[0] : ''}${'0' * (width - s.length)}$body';
    case 'isalnum':
      return s.isNotEmpty && RegExp(r'^[A-Za-z0-9äöüÄÖÜß]+$').hasMatch(s);
    case 'isspace':
      return s.isNotEmpty && RegExp(r'^\s+$').hasMatch(s);
    case 'isnumeric' || 'isdecimal':
      return s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s);
    case 'istitle':
      final words = RegExp(r'[A-Za-zäöüÄÖÜß]+').allMatches(s).map((m) => m[0]!).toList();
      return words.isNotEmpty &&
          words.every((w) => w[0] == w[0].toUpperCase() && w.substring(1) == w.substring(1).toLowerCase());
    case 'rfind' || 'rindex':
      _args(name, args, 1, 1, line);
      final i = s.lastIndexOf(_str(args[0], 'Der gesuchte Text', line));
      if (i < 0 && name == 'rindex') throw PyError(line, 'ValueError', '${pyRepr(args[0])} kommt im Text nicht vor.');
      return i;
    case 'join':
      _args(name, args, 1, 1, line);
      final items = pyIterate(args[0], line).toList();
      for (final i in items) {
        if (i is! String) throw _type(line, 'join() verbindet nur Texte, aber in der Liste steht ${pyRepr(i)}. Tipp: str() benutzen.');
      }
      return items.join(s);
    case 'find' || 'index':
      _args(name, args, 1, 3, line);
      final from = args.length > 1 && args[1] is int ? (args[1] as int).clamp(0, s.length) : 0;
      final until = args.length > 2 && args[2] is int ? (args[2] as int).clamp(from, s.length) : s.length;
      final found = s.substring(0, until).indexOf(_str(args[0], 'Der gesuchte Text', line), from);
      final i = found;
      if (i < 0 && name == 'index') throw PyError(line, 'ValueError', '${pyRepr(args[0])} kommt im Text nicht vor.');
      return i;
    case 'count':
      _args(name, args, 1, 1, line);
      final sub = _str(args[0], 'Der gesuchte Text', line);
      if (sub.isEmpty) return s.length + 1;
      return RegExp(RegExp.escape(sub)).allMatches(s).length;
    case 'startswith':
      _args(name, args, 1, 1, line);
      if (args[0] is PyTuple) return (args[0] as PyTuple).items.any((p) => s.startsWith(_str(p, 'Der Anfang', line)));
      return s.startsWith(_str(args[0], 'Der Anfang', line));
    case 'endswith':
      _args(name, args, 1, 1, line);
      if (args[0] is PyTuple) return (args[0] as PyTuple).items.any((p) => s.endsWith(_str(p, 'Das Ende', line)));
      return s.endsWith(_str(args[0], 'Das Ende', line));
    case 'capitalize':
      _args(name, args, 0, 0, line);
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
    case 'title':
      _args(name, args, 0, 0, line);
      return s.replaceAllMapped(RegExp(r'[A-Za-zäöüÄÖÜß]+'),
          (m) => m[0]![0].toUpperCase() + m[0]!.substring(1).toLowerCase());
    case 'isdigit':
      return s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s);
    case 'isalpha':
      return s.isNotEmpty && RegExp(r'^[A-Za-zäöüÄÖÜß]+$').hasMatch(s);
    case 'isupper':
      return s.contains(RegExp('[A-ZÄÖÜ]')) && s == s.toUpperCase();
    case 'islower':
      return s.contains(RegExp('[a-zäöüß]')) && s == s.toLowerCase();
    case 'format':
      var auto = 0;
      return s.replaceAllMapped(RegExp(r'\{\{|\}\}|\{([^{}]*)\}'), (m) {
        if (m[0] == '{{') return '{';
        if (m[0] == '}}') return '}';
        final inner = m[1]!;
        final colon = inner.indexOf(':');
        final field = colon < 0 ? inner : inner.substring(0, colon);
        final spec = colon < 0 ? null : inner.substring(colon + 1);
        Object? value;
        if (field.isEmpty) {
          if (auto >= args.length) throw PyError(line, 'IndexError', 'Für format() fehlen Werte: Es gibt mehr {} als Werte.');
          value = args[auto++];
        } else if (int.tryParse(field) case final i?) {
          if (i >= args.length) throw PyError(line, 'IndexError', 'format() hat keinen Wert Nummer $i.');
          value = args[i];
        } else {
          if (!kwargs.containsKey(field)) throw PyError(line, 'KeyError', 'format() hat keinen Wert namens "$field".');
          value = kwargs[field];
        }
        return formatValue(value, spec, line);
      });
  }
  return _missing;
}

Object? _listMethod(PyList l, String name, List<Object?> args, Map<String, Object?> kwargs, int line, PyContext ctx) {
  final items = l.items;
  switch (name) {
    case 'append':
      _args(name, args, 1, 1, line);
      items.add(args[0]);
      return null;
    case 'insert':
      _args(name, args, 2, 2, line);
      final i = args[0];
      if (i is! int) throw _type(line, 'Die Position bei insert() muss eine ganze Zahl sein.');
      final pos = (i < 0 ? items.length + i : i).clamp(0, items.length);
      items.insert(pos, args[1]);
      return null;
    case 'extend':
      _args(name, args, 1, 1, line);
      items.addAll(pyIterate(args[0], line));
      return null;
    case 'remove':
      _args(name, args, 1, 1, line);
      final i = items.indexWhere((e) => pyEquals(e, args[0]));
      if (i < 0) throw PyError(line, 'ValueError', '${pyRepr(args[0])} ist nicht in der Liste, deshalb kann remove() es nicht entfernen.');
      items.removeAt(i);
      return null;
    case 'pop':
      _args(name, args, 0, 1, line);
      if (items.isEmpty) throw PyError(line, 'IndexError', 'pop() geht nicht: Die Liste ist leer.');
      if (args.isEmpty) return items.removeLast();
      final value = Ops.getItem(l, args[0], line);
      items.removeAt((args[0] as int) < 0 ? items.length + (args[0] as int) : args[0] as int);
      return value;
    case 'clear':
      _args(name, args, 0, 0, line);
      items.clear();
      return null;
    case 'sort':
      _args(name, args, 0, 0, line);
      sortInPlace(items, kwargs, line, ctx);
      return null;
    case 'index' when args.length > 1:
      _args(name, args, 1, 3, line);
      final start = args[1] is int ? args[1] as int : 0;
      final i = items.indexWhere((e) => pyEquals(e, args[0]), start < 0 ? 0 : start);
      if (i < 0) throw PyError(line, 'ValueError', '${pyRepr(args[0])} ist nicht in der Liste.');
      return i;
    case 'reverse':
      _args(name, args, 0, 0, line);
      final reversed = items.reversed.toList();
      items
        ..clear()
        ..addAll(reversed);
      return null;
    case 'index':
      _args(name, args, 1, 1, line);
      final i = items.indexWhere((e) => pyEquals(e, args[0]));
      if (i < 0) throw PyError(line, 'ValueError', '${pyRepr(args[0])} ist nicht in der Liste.');
      return i;
    case 'count':
      _args(name, args, 1, 1, line);
      return items.where((e) => pyEquals(e, args[0])).length;
    case 'copy':
      _args(name, args, 0, 0, line);
      return PyList(List.of(items));
  }
  return _missing;
}

Object? _dictMethod(PyDict d, String name, List<Object?> args, Map<String, Object?> kwargs, int line) {
  switch (name) {
    case 'keys':
      return PyDictView(DictViewKind.keys, d);
    case 'values':
      return PyDictView(DictViewKind.vals, d);
    case 'items':
      return PyDictView(DictViewKind.items, d);
    case 'get':
      _args(name, args, 1, 2, line);
      return d.map.containsKey(args[0]) ? d.map[args[0]] : (args.length > 1 ? args[1] : null);
    case 'pop':
      _args(name, args, 1, 2, line);
      if (!d.map.containsKey(args[0])) {
        if (args.length > 1) return args[1];
        throw PyError(line, 'KeyError', 'Den Schlüssel ${pyRepr(args[0])} gibt es im Dictionary nicht.');
      }
      return d.map.remove(args[0]);
    case 'popitem':
      if (d.map.isEmpty) throw PyError(line, 'KeyError', 'popitem() geht nicht: Das Dictionary ist leer.');
      final last = d.map.keys.last;
      return PyTuple([last, d.map.remove(last)]);
    case 'update':
      _args(name, args, 0, 1, line);
      if (args.isNotEmpty) {
        final other = args[0];
        if (other is PyDict) {
          d.map.addAll(other.map);
        } else {
          for (final pair in pyIterate(other, line)) {
            final p = pyIterate(pair, line).toList();
            if (p.length != 2) throw _type(line, 'update() braucht ein Dictionary, z. B. auto.update({"farbe": "rot"})');
            d.map[p[0]] = p[1];
          }
        }
      }
      d.map.addAll(kwargs);
      return null;
    case 'clear':
      d.map.clear();
      return null;
    case 'copy':
      return PyDict()..map.addAll(d.map);
    case 'setdefault':
      _args(name, args, 1, 2, line);
      return d.map.putIfAbsent(args[0], () => args.length > 1 ? args[1] : null);
    case 'fromkeys':
      _args(name, args, 1, 2, line);
      final r = PyDict();
      for (final k in pyIterate(args[0], line)) {
        r.map[k] = args.length > 1 ? args[1] : null;
      }
      return r;
  }
  return _missing;
}

Object? _setMethod(PySet s, String name, List<Object?> args, int line) {
  List<Object?> other(int i) => pyIterate(args[i], line).toList();
  bool inOther(Object? e, List<Object?> o) => o.any((x) => pyEquals(x, e));
  switch (name) {
    case 'copy':
      return PySet(s.items, s.frozen);
    case 'difference':
      var result = s.items.toList();
      for (var i = 0; i < args.length; i++) {
        final o = other(i);
        result = result.where((e) => !inOther(e, o)).toList();
      }
      return PySet(result, s.frozen);
    case 'symmetric_difference':
      _args(name, args, 1, 1, line);
      final o = other(0);
      return PySet([...s.items.where((e) => !inOther(e, o)), ...o.where((e) => !s.items.contains(e))], s.frozen);
    case 'issubset':
      _args(name, args, 1, 1, line);
      final o = other(0);
      return s.items.every((e) => inOther(e, o));
    case 'issuperset':
      _args(name, args, 1, 1, line);
      return other(0).every(s.items.contains);
    case 'isdisjoint':
      _args(name, args, 1, 1, line);
      return !other(0).any(s.items.contains);
  }
  if (s.frozen) {
    if (const {'add', 'remove', 'discard', 'update', 'clear', 'pop', 'intersection_update', 'difference_update',
        'symmetric_difference_update'}.contains(name)) {
      throw PyError(line, 'AttributeError',
          'Ein frozenset kann man nicht verändern – es hat keine Methode .$name().');
    }
  }
  switch (name) {
    case 'intersection_update':
      _args(name, args, 1, 1, line);
      final o = other(0);
      s.items.removeWhere((e) => !inOther(e, o));
      return null;
    case 'difference_update':
      for (var i = 0; i < args.length; i++) {
        final o = other(i);
        s.items.removeWhere((e) => inOther(e, o));
      }
      return null;
    case 'symmetric_difference_update':
      _args(name, args, 1, 1, line);
      final o = other(0);
      final add = o.where((e) => !s.items.contains(e)).toList();
      s.items.removeWhere((e) => inOther(e, o));
      s.items.addAll(add);
      return null;
    case 'add':
      _args(name, args, 1, 1, line);
      if (!isHashable(args[0])) throw _type(line, '${pyTypeName(args[0])} kann nicht in einem Set stehen.');
      s.items.add(args[0]);
      return null;
    case 'remove':
      _args(name, args, 1, 1, line);
      if (!s.items.remove(args[0])) throw PyError(line, 'KeyError', '${pyRepr(args[0])} ist nicht im Set.');
      return null;
    case 'discard':
      _args(name, args, 1, 1, line);
      s.items.remove(args[0]);
      return null;
    case 'union':
      return PySet([...s.items, for (final a in args) ...pyIterate(a, line)], s.frozen);
    case 'intersection':
      var result = s.items.toList();
      for (var i = 0; i < args.length; i++) {
        final o = other(i);
        result = result.where((e) => inOther(e, o)).toList();
      }
      return PySet(result, s.frozen);
    case 'update':
      for (final a in args) {
        s.items.addAll(pyIterate(a, line));
      }
      return null;
    case 'clear':
      s.items.clear();
      return null;
    case 'pop':
      if (s.items.isEmpty) throw PyError(line, 'KeyError', 'pop() geht nicht: Das Set ist leer.');
      final first = s.items.first;
      s.items.remove(first);
      return first;
  }
  return _missing;
}

Object? _tupleMethod(PyTuple t, String name, List<Object?> args, int line) {
  switch (name) {
    case 'count':
      _args(name, args, 1, 1, line);
      return t.items.where((e) => pyEquals(e, args[0])).length;
    case 'index':
      _args(name, args, 1, 1, line);
      final i = t.items.indexWhere((e) => pyEquals(e, args[0]));
      if (i < 0) throw PyError(line, 'ValueError', '${pyRepr(args[0])} ist nicht im Tupel.');
      return i;
  }
  return _missing;
}


Object? _fileMethod(PyFile f, String name, List<Object?> args, int line) {
  if (f.closed && name != 'close') {
    throw PyError(line, 'ValueError', 'Die Datei ist schon geschlossen – lesen oder schreiben geht nicht mehr.');
  }
  void needRead() {
    if (!f.readable) {
      throw PyError(line, 'UnsupportedOperation', 'Die Datei wurde zum Schreiben geöffnet ("${f.mode}") – lesen geht nicht.');
    }
  }

  switch (name) {
    case 'read':
      _args(name, args, 0, 1, line);
      needRead();
      final rest = f.content.substring(f.position);
      final n = args.isEmpty || args[0] == null ? rest.length : (args[0] as int);
      final part = n < 0 || n >= rest.length ? rest : rest.substring(0, n);
      f.position += part.length;
      return part;
    case 'readline':
      _args(name, args, 0, 0, line);
      needRead();
      final rest = f.content.substring(f.position);
      final i = rest.indexOf('\n');
      final part = i < 0 ? rest : rest.substring(0, i + 1);
      f.position += part.length;
      return part;
    case 'readlines':
      _args(name, args, 0, 0, line);
      needRead();
      final rest = f.content.substring(f.position);
      f.position = f.content.length;
      return PyList(splitLinesKeepEnds(rest));
    case 'write':
      _args(name, args, 1, 1, line);
      if (f.mode.contains('r') && !f.mode.contains('+')) {
        throw PyError(line, 'UnsupportedOperation', 'Die Datei wurde nur zum Lesen geöffnet ("r") – schreiben geht nicht.');
      }
      final text = _str(args[0], 'Was man in eine Datei schreibt', line);
      f.write(text);
      return text.length;
    case 'close':
      f.closed = true;
      return null;
  }
  return _missing;
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November',
  'December',
];

String strftime(DateTime v, String format) {
  String two(int n) => n.toString().padLeft(2, '0');
  final dayOfYear = v.difference(DateTime(v.year)).inDays + 1;
  return format.replaceAllMapped(RegExp('%(.)'), (m) => switch (m[1]) {
    'Y' => v.year.toString().padLeft(4, '0'),
    'y' => two(v.year % 100),
    'm' => two(v.month),
    'd' => two(v.day),
    'H' => two(v.hour),
    'I' => two(v.hour % 12 == 0 ? 12 : v.hour % 12),
    'p' => v.hour < 12 ? 'AM' : 'PM',
    'M' => two(v.minute),
    'S' => two(v.second),
    'f' => (v.millisecond * 1000 + v.microsecond).toString().padLeft(6, '0'),
    'A' => _weekdays[v.weekday - 1],
    'a' => _weekdays[v.weekday - 1].substring(0, 3),
    'w' => '${v.weekday % 7}',
    'B' => _months[v.month - 1],
    'b' => _months[v.month - 1].substring(0, 3),
    'j' => dayOfYear.toString().padLeft(3, '0'),
    'C' => two(v.year ~/ 100),
    '%' => '%',
    _ => m[0]!,
  });
}

Object? _dateMethod(PyDateTime d, String name, List<Object?> args, int line) {
  switch (name) {
    case 'strftime':
      _args(name, args, 1, 1, line);
      return strftime(d.value, _str(args[0], 'Das Format', line));
    case 'weekday':
      return d.value.weekday - 1;
    case 'isoweekday':
      return d.value.weekday;
    case 'date':
      return PyDateTime(DateTime(d.value.year, d.value.month, d.value.day), dateOnly: true);
    case 'isoformat':
      return dateTimeStr(d).replaceFirst(' ', 'T');
  }
  return _missing;
}

Object? _matchMethod(PyReMatch m, String name, List<Object?> args, int line) {
  Object? group(Object? g) {
    if (g is String) return m.match.namedGroup(g);
    if (g is! int || g < 0 || g > m.match.groupCount) throw PyError(line, 'IndexError', 'Diese Gruppe gibt es nicht.');
    return m.match.group(g);
  }

  switch (name) {
    case 'group':
      if (args.isEmpty) return m.match.group(0);
      if (args.length == 1) return group(args[0]);
      return PyTuple([for (final a in args) group(a)]);
    case 'groups':
      return PyTuple([for (var i = 1; i <= m.match.groupCount; i++) m.match.group(i)]);
    case 'span':
      return PyTuple([m.match.start, m.match.end]);
    case 'start':
      return m.match.start;
    case 'end':
      return m.match.end;
  }
  return _missing;
}
