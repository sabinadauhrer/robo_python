import 'ast.dart';
import 'expression_parser.dart';
import 'lexer.dart';
import 'py_error.dart';
import 'tokens.dart';

/// Eine logische Codezeile (über Klammern fortgesetzte Zeilen sind zusammengefasst).
class _Line {
  _Line(this.number, this.indent, this.tokens);
  final int number;
  final int indent;
  final List<Token> tokens;
}

/// Wandelt Python-Quelltext in Anweisungen um. Blöcke werden über die Einrückung erkannt.
class Parser {
  Parser._(this._lines);

  final List<_Line> _lines;
  int _pos = 0;

  static List<Stmt> parse(String source) {
    final parser = Parser._(_logicalLines(source));
    final program = parser._block(0);
    if (parser._pos < parser._lines.length) {
      throw PyError(parser._lines[parser._pos].number, 'IndentationError',
          'Die Einrückung passt zu keiner Zeile davor.');
    }
    return program;
  }

  static const unsupported = {'async': 'async', 'await': 'await'};

  // ---------- Zeilen ----------

  static List<_Line> _logicalLines(String source) {
    final result = <_Line>[];
    final raw = source.replaceAll('\r\n', '\n').split('\n');
    _Line? open;
    var depth = 0;
    for (var i = 0; i < raw.length; i++) {
      final number = i + 1;
      var text = raw[i];
      // Mehrzeiliger Text mit """ oder ''': Folgezeilen anhängen, bis er endet.
      while (_openTriple(text) && i + 1 < raw.length) {
        i++;
        text = '$text\n${raw[i]}';
      }
      var indent = 0;
      var j = 0;
      while (j < text.length && (text[j] == ' ' || text[j] == '\t')) {
        indent += text[j] == '\t' ? 4 : 1;
        j++;
      }
      final tokens = Lexer.tokenize(text.substring(j), number);
      if (open != null) {
        open.tokens.addAll(tokens);
      } else if (tokens.isNotEmpty) {
        open = _Line(number, indent, tokens);
      }
      for (final t in tokens) {
        if (t.opens) depth++;
        if (t.closes) depth--;
      }
      if (depth < 0) {
        throw PyError(number, 'SyntaxError', 'Hier ist eine schließende Klammer zu viel.');
      }
      if (depth == 0 && open != null) {
        result.add(open);
        open = null;
      }
    }
    if (open != null) {
      throw PyError(open.number, 'SyntaxError', 'Eine Klammer wurde geöffnet, aber nie geschlossen.');
    }
    return result;
  }

  /// Steht in der Zeile ein """-Text, der nicht geschlossen wird?
  static bool _openTriple(String text) {
    String? open;
    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (open != null) {
        if (c == '\\') {
          i += 2;
          continue;
        }
        if (text.startsWith(open, i)) {
          i += open.length;
          open = null;
          continue;
        }
        i++;
        continue;
      }
      if (c == '#') return false;
      if (c == '"' || c == "'") {
        open = text.startsWith(c * 3, i) ? c * 3 : c;
        i += open.length;
        continue;
      }
      i++;
    }
    return open != null && open.length == 3;
  }

  // ---------- Blöcke ----------

  List<Stmt> _block(int indent) {
    final statements = <Stmt>[];
    while (_pos < _lines.length) {
      final line = _lines[_pos];
      if (line.indent < indent) break;
      if (line.indent > indent) {
        final previous = _pos > 0 ? _lines[_pos - 1] : null;
        if (statements.isNotEmpty && previous != null && previous.indent > line.indent) {
          throw PyError(line.number, 'IndentationError',
              'Die Einrückung passt zu keiner Zeile davor. Rücke genauso weit ein wie die anderen Zeilen im selben Block.');
        }
        throw PyError(line.number, 'IndentationError',
            'Unerwartete Einrückung. Eingerückt wird nur nach einer Zeile, die mit einem Doppelpunkt (:) endet.');
      }
      _pos++;
      if (line.tokens.first.isOp('@')) {
        statements.add(_decorated(line));
        continue;
      }
      statements.add(_statement(line));
    }
    return statements;
  }

  /// @dekorator über def oder class.
  Stmt _decorated(_Line first) {
    final decorators = <Expr>[];
    var line = first;
    while (line.tokens.first.isOp('@')) {
      if (line.tokens.length < 2) throw PyError(line.number, 'SyntaxError', 'Nach @ fehlt der Name des Dekorators.');
      decorators.add(ExpressionParser(line.tokens.sublist(1), line.number).parseAll());
      if (_pos >= _lines.length || _lines[_pos].indent != first.indent) {
        throw PyError(line.number, 'SyntaxError', 'Nach einem @dekorator muss direkt eine Funktion (def) folgen.');
      }
      line = _lines[_pos++];
    }
    final stmt = _statement(line);
    switch (stmt) {
      case DefStmt():
        stmt.decorators = decorators;
      case ClassStmt():
        stmt.decorators = decorators;
      default:
        throw PyError(line.number, 'SyntaxError', 'Nach einem @dekorator muss direkt eine Funktion (def) folgen.');
    }
    return stmt;
  }

  /// Körper eines Blocks: entweder in derselben Zeile nach dem ":" oder eingerückt darunter.
  List<Stmt> _body(_Line header, List<Token> afterColon, String what) {
    if (afterColon.isNotEmpty) return [_simpleStatement(header.number, afterColon)];
    if (_pos >= _lines.length) {
      throw PyError(header.number, 'IndentationError',
          'Nach dem Doppelpunkt fehlt der eingerückte Code für $what.');
    }
    final next = _lines[_pos];
    if (next.indent <= header.indent) {
      throw PyError(next.number, 'IndentationError',
          'Einrückung fehlt. Der Code für $what (Zeile ${header.number}) muss eingerückt sein, z. B. mit 4 Leerzeichen.');
    }
    return _block(next.indent);
  }

  /// Teilt die Kopfzeile am Doppelpunkt (außerhalb von Klammern).
  (List<Token>, List<Token>) _splitHeader(_Line line, String keyword) {
    final tokens = line.tokens;
    var depth = 0;
    var lambdas = 0;
    for (var i = 1; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.opens) depth++;
      if (t.closes) depth--;
      if (t.isName('lambda')) lambdas++;
      if (depth == 0 && t.type == TokenType.colon) {
        if (lambdas > 0) {
          lambdas--;
          continue;
        }
        return (tokens.sublist(1, i), tokens.sublist(i + 1));
      }
    }
    throw PyError(line.number, 'SyntaxError', 'Am Ende der $keyword-Zeile fehlt der Doppelpunkt ":".');
  }

  // ---------- Anweisungen ----------

  Stmt _statement(_Line line) {
    final first = line.tokens.first;
    final n = line.number;
    if (first.type == TokenType.name) {
      _checkKeywordCase(first.text, n);
      switch (first.text) {
        case 'if':
          return _if(line);
        case 'elif' || 'else':
          throw PyError(n, 'SyntaxError',
              '"${first.text}" braucht direkt davor ein passendes "if" mit gleicher Einrückung.');
        case 'while':
          final (cond, rest) = _splitHeader(line, 'while');
          final condition = _condition(cond, n, 'while');
          final body = _body(line, rest, 'die while-Schleife');
          return WhileStmt(n, condition, tokensToSource(cond), body, _loopElse(line));
        case 'for':
          return _for(line);
        case 'def':
          return _def(line);
        case 'class':
          return _class(line);
        case 'try':
          return _try(line);
        case 'except' || 'finally':
          throw PyError(n, 'SyntaxError', '"${first.text}" braucht direkt davor ein passendes "try:" mit gleicher Einrückung.');
        case 'with':
          return _with(line);
        case 'match' when line.tokens.length > 2 && line.tokens.last.type == TokenType.colon &&
            !(line.tokens[1].type == TokenType.op && line.tokens[1].text.endsWith('=')):
          return _match(line);
        case 'case':
          throw PyError(n, 'SyntaxError', '"case" gibt es nur eingerückt unter einem "match".');
      }
    }
    return _simpleStatement(n, line.tokens);
  }

  Stmt _simpleStatement(int n, List<Token> tokens) {
    final first = tokens.first;
    if (first.type == TokenType.name) {
      final word = first.text;
      if (unsupported.containsKey(word)) {
        throw PyError(n, 'SyntaxError', '${unsupported[word]} gibt es in diesem Spiel noch nicht.');
      }
      switch (word) {
        case 'pass':
          return PassStmt(n);
        case 'break':
          return BreakStmt(n);
        case 'continue':
          return ContinueStmt(n);
        case 'return':
          final rest = tokens.sublist(1);
          return ReturnStmt(n, rest.isEmpty ? null : ExpressionParser(rest, n).parseAll());
        case 'del':
          final target = ExpressionParser(tokens.sublist(1), n).parseAll();
          return DelStmt(n, target is TupleExpr ? target.items : [target]);
        case 'global':
          return GlobalStmt(n, [
            for (final t in tokens.skip(1))
              if (t.type == TokenType.name) t.text,
          ]);
        case 'nonlocal':
          return NonlocalStmt(n, [
            for (final t in tokens.skip(1))
              if (t.type == TokenType.name) t.text,
          ]);
        case 'raise':
          final rest = tokens.sublist(1);
          final from = rest.indexWhere((t) => t.isName('from'));
          final valueTokens = from < 0 ? rest : rest.sublist(0, from);
          return RaiseStmt(n, valueTokens.isEmpty ? null : ExpressionParser(valueTokens, n).parseAll());
        case 'assert':
          final rest = tokens.sublist(1);
          if (rest.isEmpty) throw PyError(n, 'SyntaxError', 'Nach assert fehlt die Bedingung.');
          var depth = 0;
          var comma = -1;
          for (var i = 0; i < rest.length; i++) {
            if (rest[i].opens) depth++;
            if (rest[i].closes) depth--;
            if (depth == 0 && rest[i].type == TokenType.comma) {
              comma = i;
              break;
            }
          }
          return AssertStmt(
            n,
            ExpressionParser(comma < 0 ? rest : rest.sublist(0, comma), n).parseAll(),
            comma < 0 ? null : ExpressionParser(rest.sublist(comma + 1), n).parseAll(),
          );
        case 'yield':
          final rest = tokens.sublist(1);
          return YieldStmt(n, rest.isEmpty ? null : ExpressionParser(rest, n).parseAll());
        case 'import':
          return _import(n, tokens);
        case 'from':
          return _fromImport(n, tokens);
        case 'if' || 'for' || 'while' || 'def' || 'else' || 'elif' || 'class' || 'try' || 'with':
          throw PyError(n, 'SyntaxError', '"$word" muss am Anfang einer eigenen Zeile stehen.');
      }
    }

    // Zuweisungen: "=" oder "+=" usw. außerhalb von Klammern suchen
    final equals = <int>[];
    var depth = 0;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.opens) depth++;
      if (t.closes) depth--;
      if (depth != 0 || t.type != TokenType.op) continue;
      if (t.text == '=') equals.add(i);
      if (const {'+=', '-=', '*=', '/=', '//=', '%=', '**=', '|=', '&=', '^=', '<<=', '>>='}.contains(t.text)) {
        final target = _target(tokens.sublist(0, i), n);
        final valueTokens = tokens.sublist(i + 1);
        if (valueTokens.isEmpty) throw PyError(n, 'SyntaxError', 'Nach "${t.text}" fehlt ein Wert.');
        return AugAssignStmt(n, target, t.text.substring(0, t.text.length - 1),
            ExpressionParser(valueTokens, n).parseAll());
      }
    }
    if (equals.isNotEmpty) {
      final targets = <Expr>[];
      var start = 0;
      for (final e in equals) {
        targets.add(_target(tokens.sublist(start, e), n));
        start = e + 1;
      }
      final valueTokens = tokens.sublist(start);
      if (valueTokens.isEmpty) {
        throw PyError(n, 'SyntaxError', 'Nach dem "=" fehlt der Wert, z. B. x = 5');
      }
      return AssignStmt(n, targets, ExpressionParser(valueTokens, n).parseAll());
    }

    if (tokens.last.type == TokenType.colon) {
      throw PyError(n, 'SyntaxError',
          'Ein Doppelpunkt am Zeilenende gehört zu if, elif, else, for, while, def, class oder try.');
    }
    final expr = ExpressionParser(tokens, n).parseAll();
    if (expr is NameExpr && const {'print', 'len', 'input'}.contains(expr.name)) {
      throw PyError(n, 'SyntaxError', 'Nach ${expr.name} fehlen die Klammern: ${expr.name}(...)');
    }
    return ExprStmt(n, expr);
  }

  Expr _target(List<Token> tokens, int n) {
    if (tokens.isEmpty) throw PyError(n, 'SyntaxError', 'Vor dem "=" fehlt der Name der Variablen.');
    final expr = ExpressionParser(tokens, n).parseAll();
    void check(Expr e) {
      switch (e) {
        case NameExpr(:final name):
          if (const {
            'True', 'False', 'None', 'if', 'for', 'while', 'def', 'in', 'and', 'or', 'not', 'class', 'return',
            'try', 'except', 'finally', 'import', 'from', 'with', 'as', 'pass', 'break', 'continue', 'lambda',
            'global', 'nonlocal', 'raise', 'is', 'elif', 'else', 'del', 'yield', 'assert',
          }.contains(name)) {
            throw PyError(n, 'SyntaxError', '"$name" ist ein reserviertes Wort und kann keine Variable sein.');
          }
        case IndexExpr() || AttributeExpr() || SliceExpr():
          break;
        case StarredExpr(:final value):
          check(value);
        case ListExpr(:final items):
          items.forEach(check);
        case TupleExpr(:final items):
          items.forEach(check);
        case Literal():
          throw PyError(n, 'SyntaxError',
              'Links vom "=" muss ein Variablenname stehen, kein Wert. Richtig wäre z. B. x = 5');
        case CallExpr():
          throw PyError(n, 'SyntaxError', 'Einem Funktionsaufruf kann man nichts zuweisen.');
        default:
          throw PyError(n, 'SyntaxError', 'Links vom "=" muss ein Variablenname stehen.');
      }
    }
    check(expr);
    return expr;
  }

  void _checkKeywordCase(String word, int line) {
    final lower = word.toLowerCase();
    if (word != lower &&
        const {'for', 'if', 'else', 'elif', 'while', 'def', 'return', 'in', 'print', 'range', 'len'}.contains(lower)) {
      throw PyError(line, 'SyntaxError',
          'Python unterscheidet Groß- und Kleinschreibung: Schreibe "$lower" statt "$word".');
    }
  }

  Expr _condition(List<Token> tokens, int n, String keyword) {
    if (tokens.isEmpty) {
      throw PyError(n, 'SyntaxError', 'Nach "$keyword" fehlt die Bedingung, z. B. $keyword x > 3:');
    }
    final p = ExpressionParser(tokens, n);
    final e = p.parseCondition();
    p.expectEnd();
    return e;
  }

  Stmt _if(_Line line) {
    IfBranch branch(_Line l, String keyword) {
      final (cond, rest) = _splitHeader(l, keyword);
      final condition = _condition(cond, l.number, keyword);
      return IfBranch(l.number, keyword, condition, tokensToSource(cond),
          _body(l, rest, 'den $keyword-Teil'));
    }

    final branches = [branch(line, 'if')];
    List<Stmt>? elseBody;
    while (_pos < _lines.length) {
      final next = _lines[_pos];
      if (next.indent != line.indent) break;
      final word = next.tokens.first;
      if (word.isName('elif')) {
        _pos++;
        branches.add(branch(next, 'elif'));
      } else if (word.isName('else')) {
        _pos++;
        if (next.tokens.length < 2 || next.tokens[1].type != TokenType.colon) {
          throw PyError(next.number, 'SyntaxError',
              'Nach "else" kommt direkt ein Doppelpunkt: else:  (else hat keine Bedingung!)');
        }
        elseBody = _body(next, next.tokens.sublist(2), 'den else-Teil');
        break;
      } else {
        break;
      }
    }
    return IfStmt(branches, elseBody);
  }

  Stmt _for(_Line line) {
    final n = line.number;
    final (header, rest) = _splitHeader(line, 'for');
    final inIndex = header.indexWhere((t) => t.isName('in'));
    if (inIndex < 1) {
      throw PyError(n, 'SyntaxError', 'So sieht eine for-Schleife aus: for x in liste:  (das "in" fehlt)');
    }
    final targets = [
      for (final t in header.sublist(0, inIndex))
        if (t.type == TokenType.name) t.text,
    ];
    if (targets.isEmpty) throw PyError(n, 'SyntaxError', 'Nach "for" fehlt der Name der Schleifenvariablen.');
    final iterableTokens = header.sublist(inIndex + 1);
    if (iterableTokens.isEmpty) {
      throw PyError(n, 'SyntaxError', 'Nach "in" fehlt, worüber die Schleife laufen soll, z. B. range(3).');
    }
    final iterable = ExpressionParser(iterableTokens, n).parseAll();
    final body = _body(line, rest, 'die for-Schleife');
    return ForStmt(n, targets, iterable, body, _loopElse(line));
  }

  /// else direkt nach einer Schleife (läuft, wenn kein break kam).
  List<Stmt>? _loopElse(_Line header) {
    if (_pos >= _lines.length) return null;
    final next = _lines[_pos];
    if (next.indent != header.indent || !next.tokens.first.isName('else')) return null;
    _pos++;
    if (next.tokens.length < 2 || next.tokens[1].type != TokenType.colon) {
      throw PyError(next.number, 'SyntaxError', 'Nach "else" kommt direkt ein Doppelpunkt: else:');
    }
    return _body(next, next.tokens.sublist(2), 'den else-Teil');
  }

  Stmt _def(_Line line) {
    final n = line.number;
    final t = line.tokens;
    if (t.length < 2 || t[1].type != TokenType.name) {
      throw PyError(n, 'SyntaxError', 'Nach "def" kommt der Name der Funktion, z. B. def hallo():');
    }
    if (t.length < 3 || t[2].type != TokenType.lparen) {
      throw PyError(n, 'SyntaxError', 'Nach dem Funktionsnamen fehlen die Klammern: def ${t[1].text}():');
    }
    final (header, rest) = _splitHeader(line, 'def');
    // header = name ( params ) [-> typ]
    var depth = 0;
    var close = -1;
    for (var k = 1; k < header.length; k++) {
      if (header[k].opens) depth++;
      if (header[k].closes) depth--;
      if (depth == 0) {
        close = k;
        break;
      }
    }
    if (close < 0) throw PyError(n, 'SyntaxError', 'Bei def fehlt die schließende Klammer ")".');
    final paramTokens = header.sublist(2, close);
    final params = <String>[];
    final defaults = <String, Expr>{};
    final keywordOnly = <String>{};
    String? varArgs;
    String? kwArgs;
    var positionalOnly = 0;
    var afterStar = false;
    var i = 0;
    while (i < paramTokens.length) {
      final p = paramTokens[i];
      if (p.isOp('/')) {
        positionalOnly = params.length;
        i++;
      } else if (p.isOp('*') || p.isOp('**')) {
        final next = i + 1 < paramTokens.length ? paramTokens[i + 1] : null;
        if (p.isOp('*') && (next == null || next.type == TokenType.comma)) {
          afterStar = true;
          i++;
        } else {
          if (next == null || next.type != TokenType.name) {
            throw PyError(n, 'SyntaxError', 'Nach ${p.text} fehlt ein Name, z. B. ${p.text}${p.text == '*' ? 'args' : 'kwargs'}');
          }
          if (p.isOp('*')) {
            varArgs = next.text;
            afterStar = true;
          } else {
            kwArgs = next.text;
          }
          i += 2;
        }
      } else if (p.type == TokenType.name) {
        params.add(p.text);
        if (afterStar) keywordOnly.add(p.text);
        i++;
        if (i < paramTokens.length && paramTokens[i].type == TokenType.colon) {
          // Typangabe (name: int) überspringen
          i++;
          var d = 0;
          while (i < paramTokens.length &&
              !(d == 0 && (paramTokens[i].type == TokenType.comma || paramTokens[i].isOp('=')))) {
            if (paramTokens[i].opens) d++;
            if (paramTokens[i].closes) d--;
            i++;
          }
        }
        if (i < paramTokens.length && paramTokens[i].isOp('=')) {
          var d = 0;
          final start = ++i;
          while (i < paramTokens.length && !(d == 0 && paramTokens[i].type == TokenType.comma)) {
            if (paramTokens[i].opens) d++;
            if (paramTokens[i].closes) d--;
            i++;
          }
          defaults[p.text] = ExpressionParser(paramTokens.sublist(start, i), n).parseAll();
        } else if (defaults.isNotEmpty && !afterStar) {
          throw PyError(n, 'SyntaxError', 'Parameter ohne Standardwert müssen vor denen mit Standardwert stehen.');
        }
      } else {
        throw PyError(n, 'SyntaxError', 'In den Klammern von def stehen nur Namen, z. B. def hallo(name):');
      }
      if (i < paramTokens.length) {
        if (paramTokens[i].type != TokenType.comma) {
          throw PyError(n, 'SyntaxError', 'Zwischen den Parametern fehlt ein Komma.');
        }
        i++;
      }
    }
    return DefStmt(
      n,
      header[0].text,
      params,
      defaults,
      _body(line, rest, 'die Funktion'),
      varArgs: varArgs,
      kwArgs: kwArgs,
      positionalOnly: positionalOnly,
      keywordOnly: keywordOnly,
    );
  }

  Stmt _class(_Line line) {
    final n = line.number;
    final t = line.tokens;
    if (t.length < 2 || t[1].type != TokenType.name) {
      throw PyError(n, 'SyntaxError', 'Nach "class" kommt der Name der Klasse, z. B. class Hund:');
    }
    final (header, rest) = _splitHeader(line, 'class');
    final bases = <Expr>[];
    if (header.length > 1) {
      if (header[1].type != TokenType.lparen || header.last.type != TokenType.rparen) {
        throw PyError(n, 'SyntaxError', 'So sieht eine Klasse aus: class Hund:  oder  class Hund(Tier):');
      }
      final inner = header.sublist(2, header.length - 1);
      if (inner.isNotEmpty) {
        final e = ExpressionParser(inner, n).parseAll();
        bases.addAll(e is TupleExpr ? e.items : [e]);
      }
    }
    return ClassStmt(n, header[0].text, bases, _body(line, rest, 'die Klasse'));
  }

  Stmt _try(_Line line) {
    final n = line.number;
    if (line.tokens.length < 2 || line.tokens[1].type != TokenType.colon) {
      throw PyError(n, 'SyntaxError', 'Nach "try" kommt direkt ein Doppelpunkt: try:');
    }
    final body = _body(line, line.tokens.sublist(2), 'den try-Teil');
    final handlers = <ExceptClause>[];
    List<Stmt>? elseBody;
    List<Stmt>? finallyBody;
    int? finallyLine;
    while (_pos < _lines.length) {
      final next = _lines[_pos];
      if (next.indent != line.indent) break;
      final word = next.tokens.first;
      if (word.isName('except') && elseBody == null && finallyBody == null) {
        _pos++;
        final (header, rest) = _splitHeader(next, 'except');
        Expr? types;
        String? name;
        if (header.isNotEmpty) {
          final asIndex = header.indexWhere((x) => x.isName('as'));
          final typeTokens = asIndex < 0 ? header : header.sublist(0, asIndex);
          if (asIndex >= 0) {
            if (asIndex + 1 >= header.length || header[asIndex + 1].type != TokenType.name) {
              throw PyError(next.number, 'SyntaxError', 'Nach "as" fehlt ein Name, z. B. except ValueError as e:');
            }
            name = header[asIndex + 1].text;
          }
          if (typeTokens.isNotEmpty) types = ExpressionParser(typeTokens, next.number).parseAll();
        }
        handlers.add(ExceptClause(next.number, types, name, _body(next, rest, 'den except-Teil')));
      } else if (word.isName('else') && handlers.isNotEmpty && elseBody == null && finallyBody == null) {
        _pos++;
        if (next.tokens.length < 2 || next.tokens[1].type != TokenType.colon) {
          throw PyError(next.number, 'SyntaxError', 'Nach "else" kommt direkt ein Doppelpunkt: else:');
        }
        elseBody = _body(next, next.tokens.sublist(2), 'den else-Teil');
      } else if (word.isName('finally') && finallyBody == null) {
        _pos++;
        if (next.tokens.length < 2 || next.tokens[1].type != TokenType.colon) {
          throw PyError(next.number, 'SyntaxError', 'Nach "finally" kommt direkt ein Doppelpunkt: finally:');
        }
        finallyLine = next.number;
        finallyBody = _body(next, next.tokens.sublist(2), 'den finally-Teil');
        break;
      } else {
        break;
      }
    }
    if (handlers.isEmpty && finallyBody == null) {
      throw PyError(n, 'SyntaxError', 'Nach dem try-Teil muss ein "except:" oder "finally:" kommen.');
    }
    return TryStmt(n, body, handlers, elseBody, finallyBody, finallyLine);
  }

  Stmt _with(_Line line) {
    final n = line.number;
    final (header, rest) = _splitHeader(line, 'with');
    final asIndex = header.lastIndexWhere((x) => x.isName('as'));
    final valueTokens = asIndex < 0 ? header : header.sublist(0, asIndex);
    if (valueTokens.isEmpty) throw PyError(n, 'SyntaxError', 'Nach "with" fehlt etwas, z. B. with open("datei.txt") as f:');
    String? name;
    if (asIndex >= 0) {
      if (asIndex + 1 >= header.length || header[asIndex + 1].type != TokenType.name) {
        throw PyError(n, 'SyntaxError', 'Nach "as" fehlt ein Name, z. B. as f');
      }
      name = header[asIndex + 1].text;
    }
    return WithStmt(n, ExpressionParser(valueTokens, n).parseAll(), name, _body(line, rest, 'den with-Block'));
  }

  Stmt _match(_Line line) {
    final n = line.number;
    final subjectTokens = line.tokens.sublist(1, line.tokens.length - 1);
    final subject = ExpressionParser(subjectTokens, n).parseAll();
    if (_pos >= _lines.length || _lines[_pos].indent <= line.indent) {
      throw PyError(n, 'IndentationError', 'Unter "match" müssen eingerückte "case"-Zeilen stehen.');
    }
    final indent = _lines[_pos].indent;
    final cases = <MatchCase>[];
    while (_pos < _lines.length && _lines[_pos].indent == indent) {
      final c = _lines[_pos];
      if (!c.tokens.first.isName('case')) {
        throw PyError(c.number, 'SyntaxError', 'Unter "match" stehen nur "case"-Zeilen, z. B. case 1:');
      }
      _pos++;
      final (header, rest) = _splitHeader(c, 'case');
      if (header.isEmpty) throw PyError(c.number, 'SyntaxError', 'Nach "case" fehlt das Muster, z. B. case 1:');
      var depth = 0;
      var guardAt = -1;
      final splits = <int>[];
      for (var i = 0; i < header.length; i++) {
        if (header[i].opens) depth++;
        if (header[i].closes) depth--;
        if (depth != 0) continue;
        if (header[i].isName('if')) {
          guardAt = i;
          break;
        }
        if (header[i].isOp('|')) splits.add(i);
      }
      final patternTokens = guardAt < 0 ? header : header.sublist(0, guardAt);
      final patterns = <MatchPattern>[];
      var start = 0;
      for (final end in [...splits, patternTokens.length]) {
        final part = patternTokens.sublist(start, end);
        start = end + 1;
        if (part.isEmpty) throw PyError(c.number, 'SyntaxError', 'Bei "|" fehlt auf einer Seite ein Wert.');
        if (part.length == 1 && part.first.type == TokenType.name &&
            !const {'True', 'False', 'None'}.contains(part.first.text)) {
          patterns.add(CapturePattern(part.first.text == '_' ? null : part.first.text));
        } else {
          patterns.add(ValuePattern(ExpressionParser(part, c.number).parseAll()));
        }
      }
      final guard = guardAt < 0 ? null : _condition(header.sublist(guardAt + 1), c.number, 'if');
      cases.add(MatchCase(c.number, patterns, tokensToSource(patternTokens), guard, _body(c, rest, 'den case-Teil')));
    }
    return MatchStmt(n, subject, tokensToSource(subjectTokens), cases);
  }

  static String _dotted(List<Token> tokens, int n) {
    final b = StringBuffer();
    for (final t in tokens) {
      if (t.type != TokenType.name && t.type != TokenType.dot) {
        throw PyError(n, 'SyntaxError', 'Ein Modulname besteht nur aus Buchstaben und Punkten, z. B. import math');
      }
      b.write(t.text);
    }
    return b.toString();
  }

  Stmt _import(int n, List<Token> tokens) {
    final rest = tokens.sublist(1);
    if (rest.isEmpty) throw PyError(n, 'SyntaxError', 'Nach "import" fehlt der Name des Moduls, z. B. import math');
    final asIndex = rest.indexWhere((t) => t.isName('as'));
    if (rest.any((t) => t.type == TokenType.comma)) {
      throw PyError(n, 'SyntaxError', 'Importiere in diesem Spiel ein Modul pro Zeile, z. B. import math');
    }
    final module = _dotted(asIndex < 0 ? rest : rest.sublist(0, asIndex), n);
    String? alias;
    if (asIndex >= 0) {
      if (asIndex + 1 >= rest.length) throw PyError(n, 'SyntaxError', 'Nach "as" fehlt der neue Name.');
      alias = rest[asIndex + 1].text;
    }
    return ImportStmt(n, module, null, alias: alias);
  }

  Stmt _fromImport(int n, List<Token> tokens) {
    final importIndex = tokens.indexWhere((t) => t.isName('import'));
    if (importIndex < 2) {
      throw PyError(n, 'SyntaxError', 'So sieht es aus: from math import sqrt');
    }
    final module = _dotted(tokens.sublist(1, importIndex), n);
    final names = <String, String>{};
    final items = tokens.sublist(importIndex + 1).where((t) => t.type != TokenType.lparen && t.type != TokenType.rparen).toList();
    if (items.isEmpty) throw PyError(n, 'SyntaxError', 'Nach "import" fehlt, was importiert werden soll.');
    if (items.length == 1 && items.first.isOp('*')) return ImportStmt(n, module, {'*': '*'});
    var i = 0;
    while (i < items.length) {
      final name = items[i];
      if (name.type != TokenType.name) throw PyError(n, 'SyntaxError', 'Nach "import" stehen Namen, z. B. from math import sqrt, pi');
      var alias = name.text;
      i++;
      if (i < items.length && items[i].isName('as')) {
        if (i + 1 >= items.length) throw PyError(n, 'SyntaxError', 'Nach "as" fehlt der neue Name.');
        alias = items[i + 1].text;
        i += 2;
      }
      names[name.text] = alias;
      if (i < items.length && items[i].type == TokenType.comma) i++;
    }
    return ImportStmt(n, module, names);
  }
}
