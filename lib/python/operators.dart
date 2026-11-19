import 'dart:math' as math;

import 'py_error.dart';
import 'values.dart';

/// Rechen- und Vergleichsoperatoren mit Python-Semantik.
abstract final class Ops {
  static PyError typeError(int line, String message) => PyError(line, 'TypeError', message);

  static String _t(Object? v) => '${pyTypeName(v)} (${germanTypeName(v)})';

  static Object? number(num n) => n is int ? n : PyFloat(n.toDouble());

  static Object? binary(String op, Object? a, Object? b, int line) {
    final x = asNumber(a);
    final y = asNumber(b);
    if (x != null && y != null) {
      if (const {'&', '|', '^', '<<', '>>'}.contains(op)) return _bits(op, a, b, line);
      return _numeric(op, x, y, a is PyFloat || b is PyFloat, line);
    }
    if (a is PySet && b is PySet) {
      final frozen = a.frozen;
      switch (op) {
        case '|':
          return PySet([...a.items, ...b.items], frozen);
        case '&':
          return PySet(a.items.where(b.items.contains), frozen);
        case '^':
          return PySet([...a.items.where((e) => !b.items.contains(e)), ...b.items.where((e) => !a.items.contains(e))], frozen);
      }
    }
    if (op == '|' && a is PyDict && b is PyDict) {
      return PyDict()
        ..map.addAll(a.map)
        ..map.addAll(b.map);
    }

    switch (op) {
      case '+':
        if (a is String && b is String) return a + b;
        if (a is PyList && b is PyList) return PyList([...a.items, ...b.items]);
        if (a is PyTuple && b is PyTuple) return PyTuple([...a.items, ...b.items]);
        if ((a is String && y != null) || (x != null && b is String)) {
          throw typeError(line,
              'Text und Zahl kann man nicht mit + verbinden. Wandle die Zahl mit str() um, z. B. "Alter: " + str(alter)');
        }
      case '*':
        if (a is String && b is int) return a * math.max(0, b);
        if (a is int && b is String) return b * math.max(0, a);
        if (a is PyList && b is int) return PyList([for (var i = 0; i < b; i++) ...a.items]);
        if (a is PyTuple && b is int) return PyTuple([for (var i = 0; i < b; i++) ...a.items]);
      case '-':
        if (a is PySet && b is PySet) return PySet(a.items.where((e) => !b.items.contains(e)));
      case '%':
        if (a is String) {
          throw typeError(line, 'Das alte %-Format für Texte gibt es hier nicht. Benutze f-Strings: f"Hallo {name}"');
        }
    }
    throw typeError(line, 'Der Operator "$op" passt nicht zu ${_t(a)} und ${_t(b)}.');
  }

  static Object? _bits(String op, Object? a, Object? b, int line) {
    if (a is PyFloat || b is PyFloat) {
      throw typeError(line, 'Der Operator "$op" funktioniert nur mit ganzen Zahlen, nicht mit Kommazahlen.');
    }
    final x = asNumber(a)!.toInt();
    final y = asNumber(b)!.toInt();
    final bothBool = a is bool && b is bool;
    switch (op) {
      case '&':
        return bothBool ? (a && b) : x & y;
      case '|':
        return bothBool ? (a || b) : x | y;
      case '^':
        return bothBool ? (a != b) : x ^ y;
      case '<<':
        if (y < 0) throw PyError(line, 'ValueError', 'Man kann nicht um eine negative Anzahl Stellen verschieben.');
        return x << y;
      default:
        if (y < 0) throw PyError(line, 'ValueError', 'Man kann nicht um eine negative Anzahl Stellen verschieben.');
        return x >> y;
    }
  }

  static Object? _numeric(String op, num x, num y, bool isFloat, int line) {
    void checkZero() {
      if (y == 0) throw PyError(line, 'ZeroDivisionError', 'Durch 0 kann man nicht teilen.');
    }

    switch (op) {
      case '+':
        return isFloat ? PyFloat((x + y).toDouble()) : x + y;
      case '-':
        return isFloat ? PyFloat((x - y).toDouble()) : x - y;
      case '*':
        return isFloat ? PyFloat((x * y).toDouble()) : x * y;
      case '/':
        checkZero();
        return PyFloat(x / y);
      case '//':
        checkZero();
        final q = (x / y).floorToDouble();
        return isFloat ? PyFloat(q) : q.toInt();
      case '%':
        checkZero();
        final r = x - (x / y).floorToDouble() * y;
        return isFloat ? PyFloat(r.toDouble()) : r.toInt();
      case '**':
        if (!isFloat && y >= 0) {
          var result = 1;
          for (var i = 0; i < y; i++) {
            result *= x.toInt();
          }
          return result;
        }
        return PyFloat(math.pow(x, y).toDouble());
    }
    throw typeError(line, 'Den Operator "$op" kenne ich nicht.');
  }

  static Object? unary(String op, Object? v, int line) {
    if (op == 'not') return !pyTruthy(v);
    final n = asNumber(v);
    if (n == null) throw typeError(line, 'Vor ${_t(v)} kann kein "$op" stehen.');
    if (op == '~') {
      if (v is PyFloat) throw typeError(line, '~ funktioniert nur mit ganzen Zahlen.');
      return ~n.toInt();
    }
    if (op == '+') return number(n);
    return v is PyFloat ? PyFloat(-v.value) : -(n as int);
  }

  /// Ein einzelner Vergleich, z. B. a < b oder x in liste.
  static bool compare(String op, Object? a, Object? b, int line) {
    switch (op) {
      case '==':
        return pyEquals(a, b);
      case '!=':
        return !pyEquals(a, b);
      case 'is':
        return a == null || b == null ? a == b : identical(a, b) || (a is bool && a == b);
      case 'is not':
        return !compare('is', a, b, line);
      case 'in':
        return contains(b, a, line);
      case 'not in':
        return !contains(b, a, line);
    }
    final c = order(a, b, line, op);
    return switch (op) {
      '<' => c < 0,
      '>' => c > 0,
      '<=' => c <= 0,
      _ => c >= 0,
    };
  }

  /// Reihenfolge zweier Werte (für <, >, sort, min, max).
  static int order(Object? a, Object? b, int line, [String op = '<']) {
    final x = asNumber(a);
    final y = asNumber(b);
    if (x != null && y != null) return x.compareTo(y);
    if (a is String && b is String) return _compareStrings(a, b);
    if (a is PyDateTime && b is PyDateTime) return a.value.compareTo(b.value);
    if (a is PySet && b is PySet) {
      // Teilmenge: a <= b
      final sub = a.items.every(b.items.contains);
      final sup = b.items.every(a.items.contains);
      if (sub && sup) return 0;
      if (sub) return -1;
      if (sup) return 1;
      return op == '<' || op == '<=' ? 1 : -1;
    }
    if ((a is PyList && b is PyList) || (a is PyTuple && b is PyTuple)) {
      final l1 = a is PyList ? a.items : (a as PyTuple).items;
      final l2 = b is PyList ? b.items : (b as PyTuple).items;
      for (var i = 0; i < math.min(l1.length, l2.length); i++) {
        final c = order(l1[i], l2[i], line, op);
        if (c != 0) return c;
      }
      return l1.length.compareTo(l2.length);
    }
    throw typeError(line, '${_t(a)} und ${_t(b)} kann man nicht mit "$op" vergleichen.');
  }

  /// Vergleicht nach Unicode-Codepunkten (wie Python).
  static int _compareStrings(String a, String b) {
    final x = a.runes.toList();
    final y = b.runes.toList();
    for (var i = 0; i < math.min(x.length, y.length); i++) {
      if (x[i] != y[i]) return x[i].compareTo(y[i]);
    }
    return x.length.compareTo(y.length);
  }

  static bool contains(Object? container, Object? item, int line) {
    switch (container) {
      case String s:
        if (item is! String) throw typeError(line, 'Mit "in" sucht man in einem Text nur nach Text, nicht nach ${_t(item)}.');
        return s.contains(item);
      case PyList l:
        return l.items.any((e) => pyEquals(e, item));
      case PyTuple t:
        return t.items.any((e) => pyEquals(e, item));
      case PyDict d:
        return d.map.containsKey(item);
      case PySet s:
        return s.items.contains(item);
      case PyRange r:
        return item is int && r.values.contains(item);
      case PyDictView v:
        return v.items.any((e) => pyEquals(e, item));
    }
    throw typeError(line, 'In ${_t(container)} kann man nicht mit "in" suchen.');
  }

  // ---------- Index und Slices ----------

  static int _index(Object? key, int length, int line, String what) {
    if (key is! int) {
      throw typeError(line, 'Der Index für $what muss eine ganze Zahl sein, nicht ${_t(key)}.');
    }
    final i = key < 0 ? length + key : key;
    if (i < 0 || i >= length) {
      throw PyError(line, 'IndexError',
          'Index $key gibt es nicht. $what hat $length Elemente, also Index 0 bis ${length - 1}'
          '${length > 0 ? ' (oder -1 bis -$length)' : ''}.');
    }
    return i;
  }

  static Object? getItem(Object? container, Object? key, int line) {
    switch (container) {
      case String s:
        return s[_index(key, s.length, line, 'Der Text')];
      case PyList l:
        return l.items[_index(key, l.items.length, line, 'Die Liste')];
      case PyTuple t:
        return t.items[_index(key, t.items.length, line, 'Das Tupel')];
      case PyRange r:
        return r.values.elementAt(_index(key, r.length, line, 'Der Bereich'));
      case PyDict d:
        if (!isHashable(key)) throw typeError(line, '${_t(key)} kann kein Schlüssel sein.');
        if (!d.map.containsKey(key)) {
          throw PyError(line, 'KeyError', 'Den Schlüssel ${pyRepr(key)} gibt es im Dictionary nicht.');
        }
        return d.map[key];
      case PySet():
        throw typeError(line, 'Ein Set hat keine Reihenfolge – deshalb gibt es keinen Index wie set[0].');
    }
    throw typeError(line, '${_t(container)} hat keine Elemente, auf die man mit [ ] zugreifen kann.');
  }

  static void setItem(Object? container, Object? key, Object? value, int line) {
    switch (container) {
      case PyList l:
        l.items[_index(key, l.items.length, line, 'Die Liste')] = value;
        return;
      case PyDict d:
        if (!isHashable(key)) throw typeError(line, '${_t(key)} kann kein Schlüssel sein.');
        d.map[key] = value;
        return;
      case String _:
        throw typeError(line, 'Texte kann man nicht verändern. Erstelle einen neuen Text, z. B. mit replace().');
      case PyTuple _:
        throw typeError(line, 'Tupel kann man nicht verändern. Wandle es mit list() in eine Liste um.');
    }
    throw typeError(line, 'In ${_t(container)} kann man mit [ ] nichts speichern.');
  }

  static void deleteItem(Object? container, Object? key, int line) {
    switch (container) {
      case PyList l:
        l.items.removeAt(_index(key, l.items.length, line, 'Die Liste'));
        return;
      case PyDict d:
        if (d.map.remove(key) == null && !d.map.containsKey(key)) {
          throw PyError(line, 'KeyError', 'Den Schlüssel ${pyRepr(key)} gibt es im Dictionary nicht.');
        }
        return;
    }
    throw typeError(line, 'Aus ${_t(container)} kann man mit del nichts löschen.');
  }

  static Object? slice(Object? container, Object? start, Object? stop, Object? step, int line) {
    final List<Object?> items;
    switch (container) {
      case String s:
        items = s.split('');
      case PyList l:
        items = l.items;
      case PyTuple t:
        items = t.items;
      default:
        throw typeError(line, 'Von ${_t(container)} kann man keinen Ausschnitt [a:b] nehmen.');
    }
    int? asInt(Object? v, String name) {
      if (v == null) return null;
      if (v is int) return v;
      throw typeError(line, '$name im Ausschnitt muss eine ganze Zahl sein.');
    }

    final n = items.length;
    final st = asInt(step, 'Die Schrittweite') ?? 1;
    if (st == 0) throw PyError(line, 'ValueError', 'Die Schrittweite darf nicht 0 sein.');
    int norm(int? v, int dflt) {
      if (v == null) return dflt;
      var r = v < 0 ? v + n : v;
      if (st > 0) {
        r = r.clamp(0, n);
      } else {
        r = r.clamp(-1, n - 1);
      }
      return r;
    }

    final a = norm(asInt(start, 'Der Start'), st > 0 ? 0 : n - 1);
    final b = norm(asInt(stop, 'Das Ende'), st > 0 ? n : -1);
    final result = <Object?>[
      if (st > 0)
        for (var i = a; i < b; i += st) items[i]
      else
        for (var i = a; i > b; i += st) items[i],
    ];
    return switch (container) {
      String _ => result.join(),
      PyTuple _ => PyTuple(result),
      _ => PyList(result),
    };
  }
}
