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

  static const unsupported = {
    'class': 'Klassen', 'try': 'try/except', 'except': 'try/except', 'finally': 'try/finally',
    'import': 'import', 'from': 'import', 'with': 'with', 'yield': 'yield', 'async': 'async',
    'await': 'await', 'raise': 'raise', 'assert': 'assert', 'nonlocal': 'nonlocal', 'match': 'match',
  };

  // ---------- Zeilen ----------

  static List<_Line> _logicalLines(String source) {
    final result = <_Line>[];
    final raw = source.replaceAll('\r\n', '\n').split('\n');
    _Line? open;
    var depth = 0;
    for (var i = 0; i < raw.length; i++) {
      final number = i + 1;
      final text = raw[i];
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
      statements.add(_statement(line));
    }
    return statements;
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
          return WhileStmt(n, condition, tokensToSource(cond), _body(line, rest, 'die while-Schleife'));
        case 'for':
          return _for(line);
        case 'def':
          return _def(line);
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
        case 'if' || 'for' || 'while' || 'def' || 'else' || 'elif':
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
      if (const {'+=', '-=', '*=', '/=', '//=', '%=', '**='}.contains(t.text)) {
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
          'Ein Doppelpunkt am Zeilenende gehört zu if, elif, else, for, while oder def.');
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
          if (const {'True', 'False', 'None', 'if', 'for', 'while', 'def', 'in', 'and', 'or', 'not'}.contains(name)) {
            throw PyError(n, 'SyntaxError', '"$name" ist ein reserviertes Wort und kann keine Variable sein.');
          }
        case IndexExpr():
          break;
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
    return ForStmt(n, targets, iterable, _body(line, rest, 'die for-Schleife'));
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
    final close = header.lastIndexWhere((x) => x.type == TokenType.rparen);
    final paramTokens = header.sublist(2, close);
    final params = <String>[];
    final defaults = <String, Expr>{};
    var i = 0;
    while (i < paramTokens.length) {
      final p = paramTokens[i];
      if (p.type != TokenType.name) {
        throw PyError(n, 'SyntaxError', 'In den Klammern von def stehen nur Namen, z. B. def hallo(name):');
      }
      params.add(p.text);
      i++;
      if (i < paramTokens.length && paramTokens[i].isOp('=')) {
        var depth = 0;
        final start = ++i;
        while (i < paramTokens.length && !(depth == 0 && paramTokens[i].type == TokenType.comma)) {
          if (paramTokens[i].opens) depth++;
          if (paramTokens[i].closes) depth--;
          i++;
        }
        defaults[p.text] = ExpressionParser(paramTokens.sublist(start, i), n).parseAll();
      } else if (defaults.isNotEmpty) {
        throw PyError(n, 'SyntaxError', 'Parameter ohne Standardwert müssen vor denen mit Standardwert stehen.');
      }
      if (i < paramTokens.length && paramTokens[i].type == TokenType.comma) i++;
    }
    return DefStmt(n, header[0].text, params, defaults, _body(line, rest, 'die Funktion'));
  }
}
