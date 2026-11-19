import 'ast.dart';
import 'lexer.dart';
import 'py_error.dart';
import 'tokens.dart';
import 'values.dart';

/// Rekursiver Abstieg für Python-Ausdrücke.
///
/// Rangfolge (schwach → stark): lambda → x if c else y → or → and → not →
/// Vergleich (auch in, is) → + - → * / // % → Vorzeichen → ** → Aufruf/Index/Attribut → Grundausdruck
class ExpressionParser {
  ExpressionParser(this.tokens, this.line);

  final List<Token> tokens;
  final int line;
  int pos = 0;

  bool get isAtEnd => pos >= tokens.length;
  Token? get peek => isAtEnd ? null : tokens[pos];
  Token? peekAt(int offset) => pos + offset < tokens.length ? tokens[pos + offset] : null;

  PyError _error(String message) => PyError(line, 'SyntaxError', message);

  static const singleEqualsMessage =
      'Zum Vergleichen benutzt man == (zwei Gleichheitszeichen). '
      'Ein einzelnes = speichert einen Wert in einer Variablen.';

  /// Parst alle Tokens als einen Ausdruck (Kommas ergeben ein Tupel).
  Expr parseAll() {
    if (tokens.isEmpty) throw _error('Hier fehlt ein Wert.');
    final expr = parseExpressionList();
    expectEnd();
    return expr;
  }

  void expectEnd() {
    if (isAtEnd) return;
    final t = peek!;
    if (t.isOp('=')) throw _error(singleEqualsMessage);
    if (t.closes) throw _error('Hier ist eine schließende Klammer "${t.text}" zu viel.');
    throw _error('Unerwartetes "${t.source}" an dieser Stelle.');
  }

  /// a, b, c  → Tupel; ein einzelner Ausdruck bleibt einzeln.
  Expr parseExpressionList() {
    final first = parseExpression();
    if (peek?.type != TokenType.comma) return first;
    final items = [first];
    while (peek?.type == TokenType.comma) {
      pos++;
      if (isAtEnd || _endsList(peek!)) break;
      items.add(parseExpression());
    }
    return TupleExpr(items);
  }

  bool _endsList(Token t) => t.closes || t.isOp('=') || t.type == TokenType.colon;

  Expr parseExpression() {
    if (peek?.isName('lambda') ?? false) return _lambda();
    final value = _or();
    if (peek?.isName('if') ?? false) {
      pos++;
      final condition = _or();
      if (!(peek?.isName('else') ?? false)) {
        throw _error('Bei "wert if bedingung else anderer_wert" fehlt das else.');
      }
      pos++;
      return CondExpr(condition, value, parseExpression());
    }
    return value;
  }

  Expr _lambda() {
    pos++; // lambda
    final params = <String>[];
    final defaults = <String, Expr>{};
    while (peek != null && peek!.type != TokenType.colon) {
      final t = tokens[pos++];
      if (t.type != TokenType.name) throw _error('Nach lambda kommen Namen, z. B. lambda x: x * 2');
      params.add(t.text);
      if (peek?.isOp('=') ?? false) {
        pos++;
        defaults[t.text] = _or();
      }
      if (peek?.type == TokenType.comma) pos++;
    }
    if (peek?.type != TokenType.colon) throw _error('Bei lambda fehlt der Doppelpunkt, z. B. lambda x: x * 2');
    pos++;
    return LambdaExpr(params, defaults, parseExpression());
  }

  Expr _or() {
    var left = _and();
    while (peek?.isName('or') ?? false) {
      pos++;
      left = BinaryExpr('or', left, _and());
    }
    return left;
  }

  Expr _and() {
    var left = _not();
    while (peek?.isName('and') ?? false) {
      pos++;
      left = BinaryExpr('and', left, _not());
    }
    return left;
  }

  Expr _not() {
    if (peek?.isName('not') ?? false) {
      pos++;
      return UnaryExpr('not', _not());
    }
    return _comparison();
  }

  static const _compareOps = {'==', '!=', '<', '>', '<=', '>='};

  Expr _comparison() {
    final first = _additive();
    final ops = <String>[];
    final rest = <Expr>[];
    while (true) {
      final t = peek;
      if (t == null) break;
      String? op;
      if (t.type == TokenType.op && _compareOps.contains(t.text)) {
        op = t.text;
        pos++;
      } else if (t.isName('in')) {
        op = 'in';
        pos++;
      } else if (t.isName('not') && (peekAt(1)?.isName('in') ?? false)) {
        op = 'not in';
        pos += 2;
      } else if (t.isName('is')) {
        pos++;
        if (peek?.isName('not') ?? false) {
          pos++;
          op = 'is not';
        } else {
          op = 'is';
        }
      } else if (t.isOp('=') && ops.isEmpty && _insideCondition) {
        throw _error(singleEqualsMessage);
      }
      if (op == null) break;
      ops.add(op);
      rest.add(_additive());
    }
    return ops.isEmpty ? first : CompareExpr(first, ops, rest);
  }

  /// Wird vom Parser gesetzt, wenn eine Bedingung (if/while) gelesen wird.
  bool _insideCondition = false;

  Expr parseCondition() {
    _insideCondition = true;
    final e = parseExpression();
    _insideCondition = false;
    return e;
  }

  Expr _additive() {
    var left = _term();
    while (peek != null && (peek!.isOp('+') || peek!.isOp('-'))) {
      final op = tokens[pos++].text;
      left = BinaryExpr(op, left, _term());
    }
    return left;
  }

  Expr _term() {
    var left = _unary();
    while (peek != null && peek!.type == TokenType.op && const {'*', '/', '//', '%'}.contains(peek!.text)) {
      final op = tokens[pos++].text;
      left = BinaryExpr(op, left, _unary());
    }
    return left;
  }

  Expr _unary() {
    if (peek != null && (peek!.isOp('-') || peek!.isOp('+'))) {
      final op = tokens[pos++].text;
      return UnaryExpr(op, _unary());
    }
    return _power();
  }

  Expr _power() {
    final base = _postfix();
    if (peek?.isOp('**') ?? false) {
      pos++;
      return BinaryExpr('**', base, _unary());
    }
    return base;
  }

  Expr _postfix() {
    var expr = _atom();
    while (!isAtEnd) {
      final t = peek!;
      if (t.type == TokenType.lparen) {
        pos++;
        expr = _call(expr);
      } else if (t.type == TokenType.lbracket) {
        pos++;
        expr = _subscript(expr);
      } else if (t.type == TokenType.dot) {
        pos++;
        final name = peek;
        if (name == null || name.type != TokenType.name) throw _error('Nach dem Punkt fehlt ein Name, z. B. text.upper()');
        pos++;
        expr = AttributeExpr(expr, name.text);
      } else {
        break;
      }
    }
    return expr;
  }

  Expr _call(Expr callee) {
    final args = <Expr>[];
    final kwargs = <String, Expr>{};
    while (peek?.type != TokenType.rparen) {
      if (isAtEnd) throw _error('Hier fehlt eine schließende Klammer ")".');
      if (peek!.type == TokenType.name && (peekAt(1)?.isOp('=') ?? false)) {
        final name = tokens[pos].text;
        pos += 2;
        kwargs[name] = parseExpression();
      } else {
        if (kwargs.isNotEmpty) throw _error('Benannte Werte (name=...) müssen nach den normalen Werten kommen.');
        args.add(parseExpression());
      }
      if (peek?.type == TokenType.comma) {
        pos++;
      } else if (peek?.type != TokenType.rparen) {
        if (isAtEnd) throw _error('Hier fehlt eine schließende Klammer ")".');
        if (peek!.isOp('=')) throw _error(singleEqualsMessage);
        throw _error('Zwischen den Werten in den Klammern fehlt ein Komma.');
      }
    }
    pos++;
    return CallExpr(callee, args, kwargs);
  }

  Expr _subscript(Expr target) {
    Expr? start;
    if (peek?.type != TokenType.colon) start = parseExpression();
    if (peek?.type == TokenType.colon) {
      pos++;
      Expr? stop;
      Expr? step;
      if (peek != null && peek!.type != TokenType.rbracket && peek!.type != TokenType.colon) {
        stop = parseExpression();
      }
      if (peek?.type == TokenType.colon) {
        pos++;
        if (peek?.type != TokenType.rbracket) step = parseExpression();
      }
      _expect(TokenType.rbracket, ']');
      return SliceExpr(target, start, stop, step);
    }
    _expect(TokenType.rbracket, ']');
    if (start == null) throw _error('In den eckigen Klammern fehlt der Index, z. B. liste[0]');
    return IndexExpr(target, start);
  }

  void _expect(TokenType type, String text) {
    if (peek?.type != type) throw _error('Hier fehlt "$text".');
    pos++;
  }

  Expr _atom() {
    final t = peek;
    if (t == null) throw _error('Der Ausdruck ist unvollständig – hier fehlt noch etwas.');
    pos++;
    switch (t.type) {
      case TokenType.integer:
        return Literal(int.parse(t.text));
      case TokenType.float:
        return Literal(PyFloat(double.parse(t.text)));
      case TokenType.string:
        var text = t.text;
        while (peek?.type == TokenType.string) {
          text += tokens[pos++].text; // "a" "b" → "ab"
        }
        return Literal(text);
      case TokenType.fstring:
        return _fstring(t.text);
      case TokenType.name:
        switch (t.text) {
          case 'True':
            return const Literal(true);
          case 'False':
            return const Literal(false);
          case 'None':
            return const Literal(null);
          case 'true' || 'false' || 'none':
            final fixed = t.text[0].toUpperCase() + t.text.substring(1);
            throw _error('Python schreibt $fixed mit großem Anfangsbuchstaben.');
        }
        return NameExpr(t.text);
      case TokenType.lparen:
        if (peek?.type == TokenType.rparen) {
          pos++;
          return const TupleExpr([]);
        }
        final inner = parseExpressionList();
        _expect(TokenType.rparen, ')');
        return inner;
      case TokenType.lbracket:
        return _list();
      case TokenType.lbrace:
        return _dictOrSet();
      case TokenType.rparen || TokenType.rbracket || TokenType.rbrace:
        throw _error('Hier ist eine schließende Klammer "${t.text}" zu viel.');
      case TokenType.op || TokenType.comma || TokenType.colon || TokenType.dot:
        if (t.isOp('=')) throw _error('Vor dem = fehlt etwas.');
        throw _error('Unerwartetes "${t.text}" – hier fehlt ein Wert.');
    }
  }

  Expr _list() {
    if (peek?.type == TokenType.rbracket) {
      pos++;
      return const ListExpr([]);
    }
    final first = parseExpression();
    if (peek?.isName('for') ?? false) return _comprehension(first);
    final items = [first];
    while (peek?.type == TokenType.comma) {
      pos++;
      if (peek?.type == TokenType.rbracket) break;
      items.add(parseExpression());
    }
    if (peek?.type != TokenType.rbracket) {
      throw _error(isAtEnd ? 'Die Liste wurde nicht mit "]" geschlossen.' : 'Zwischen den Listen-Elementen fehlt ein Komma.');
    }
    pos++;
    return ListExpr(items);
  }

  Expr _comprehension(Expr element) {
    pos++; // for
    final targets = <String>[];
    while (peek != null && !peek!.isName('in')) {
      final t = tokens[pos++];
      if (t.type == TokenType.name) targets.add(t.text);
    }
    if (targets.isEmpty || !(peek?.isName('in') ?? false)) {
      throw _error('So sieht eine List Comprehension aus: [x * 2 for x in liste]');
    }
    pos++;
    final iterable = _or();
    Expr? condition;
    if (peek?.isName('if') ?? false) {
      pos++;
      condition = _or();
    }
    _expect(TokenType.rbracket, ']');
    return ListCompExpr(element, targets, iterable, condition);
  }

  Expr _dictOrSet() {
    if (peek?.type == TokenType.rbrace) {
      pos++;
      return const DictExpr([], []);
    }
    final first = parseExpression();
    if (peek?.type == TokenType.colon) {
      final keys = [first];
      final values = <Expr>[];
      pos++;
      values.add(parseExpression());
      while (peek?.type == TokenType.comma) {
        pos++;
        if (peek?.type == TokenType.rbrace) break;
        keys.add(parseExpression());
        if (peek?.type != TokenType.colon) throw _error('Im Dictionary fehlt ein Doppelpunkt zwischen Schlüssel und Wert.');
        pos++;
        values.add(parseExpression());
      }
      if (peek?.type != TokenType.rbrace) {
        throw _error(isAtEnd ? 'Das Dictionary wurde nicht mit "}" geschlossen.' : 'Zwischen den Einträgen fehlt ein Komma.');
      }
      pos++;
      return DictExpr(keys, values);
    }
    final items = [first];
    while (peek?.type == TokenType.comma) {
      pos++;
      if (peek?.type == TokenType.rbrace) break;
      items.add(parseExpression());
    }
    _expect(TokenType.rbrace, '}');
    return SetExpr(items);
  }

  Expr _fstring(String content) {
    final parts = <Object>[];
    final text = StringBuffer();
    var i = 0;
    while (i < content.length) {
      final c = content[i];
      if (c == '{' && i + 1 < content.length && content[i + 1] == '{') {
        text.write('{');
        i += 2;
      } else if (c == '}' && i + 1 < content.length && content[i + 1] == '}') {
        text.write('}');
        i += 2;
      } else if (c == '{') {
        var depth = 1;
        var j = i + 1;
        while (j < content.length && depth > 0) {
          if (content[j] == '{') depth++;
          if (content[j] == '}') depth--;
          if (depth > 0) j++;
        }
        if (depth > 0) throw _error('Im f-String fehlt eine schließende geschweifte Klammer "}".');
        final inner = content.substring(i + 1, j);
        if (inner.trim().isEmpty) throw _error('Im f-String steht {} ohne Inhalt. Schreibe z. B. {name}.');
        if (text.isNotEmpty) {
          parts.add(text.toString());
          text.clear();
        }
        final colon = _topLevelColon(inner);
        final exprText = colon < 0 ? inner : inner.substring(0, colon);
        final spec = colon < 0 ? null : inner.substring(colon + 1);
        final expr = ExpressionParser(Lexer.tokenize(exprText, line), line).parseAll();
        parts.add(FStringField(expr, spec));
        i = j + 1;
      } else if (c == '}') {
        throw _error('Im f-String steht eine "}" ohne passende "{".');
      } else {
        text.write(c);
        i++;
      }
    }
    if (text.isNotEmpty) parts.add(text.toString());
    return FStringExpr(parts);
  }

  static int _topLevelColon(String s) {
    var depth = 0;
    String? quote;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (quote != null) {
        if (c == quote) quote = null;
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if ('([{'.contains(c)) {
        depth++;
      } else if (')]}'.contains(c)) {
        depth--;
      } else if (c == ':' && depth == 0) {
        return i;
      }
    }
    return -1;
  }
}
