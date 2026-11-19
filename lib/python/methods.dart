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
    PyDict d => _dictMethod(d, name, args, line),
    PySet s => _setMethod(s, name, args, line),
    PyTuple t => _tupleMethod(t, name, args, line),
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
      _args(name, args, 2, 2, line);
      return s.replaceAll(_str(args[0], 'Der gesuchte Text', line), _str(args[1], 'Der neue Text', line));
    case 'split':
      _args(name, args, 0, 1, line);
      final sep = args.isEmpty || args[0] == null ? null : _str(args[0], 'Das Trennzeichen', line);
      final parts = sep == null ? s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty) : s.split(sep);
      return PyList(parts.toList());
    case 'join':
      _args(name, args, 1, 1, line);
      final items = pyIterate(args[0], line).toList();
      for (final i in items) {
        if (i is! String) throw _type(line, 'join() verbindet nur Texte, aber in der Liste steht ${pyRepr(i)}. Tipp: str() benutzen.');
      }
      return items.join(s);
    case 'find' || 'index':
      _args(name, args, 1, 1, line);
      final i = s.indexOf(_str(args[0], 'Der gesuchte Text', line));
      if (i < 0 && name == 'index') throw PyError(line, 'ValueError', '${pyRepr(args[0])} kommt im Text nicht vor.');
      return i;
    case 'count':
      _args(name, args, 1, 1, line);
      final sub = _str(args[0], 'Der gesuchte Text', line);
      if (sub.isEmpty) return s.length + 1;
      return RegExp(RegExp.escape(sub)).allMatches(s).length;
    case 'startswith':
      _args(name, args, 1, 1, line);
      return s.startsWith(_str(args[0], 'Der Anfang', line));
    case 'endswith':
      _args(name, args, 1, 1, line);
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

Object? _dictMethod(PyDict d, String name, List<Object?> args, int line) {
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
      _args(name, args, 1, 1, line);
      final other = args[0];
      if (other is! PyDict) throw _type(line, 'update() braucht ein Dictionary, z. B. auto.update({"farbe": "rot"})');
      d.map.addAll(other.map);
      return null;
    case 'clear':
      d.map.clear();
      return null;
    case 'copy':
      return PyDict()..map.addAll(d.map);
    case 'setdefault':
      _args(name, args, 1, 2, line);
      return d.map.putIfAbsent(args[0], () => args.length > 1 ? args[1] : null);
  }
  return _missing;
}

Object? _setMethod(PySet s, String name, List<Object?> args, int line) {
  switch (name) {
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
      return PySet([...s.items, for (final a in args) ...pyIterate(a, line)]);
    case 'intersection':
      _args(name, args, 1, 1, line);
      final other = pyIterate(args[0], line).toList();
      return PySet(s.items.where((e) => other.any((o) => pyEquals(o, e))));
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
