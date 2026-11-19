import 'py_error.dart';
import 'tokens.dart';

/// Zerlegt eine Zeile (ohne Einrückung) in Tokens. Kommentare werden entfernt.
abstract final class Lexer {
  static const _threeCharOps = {'//=', '**=', '<<=', '>>='};
  static const _twoCharOps = {
    '==', '!=', '<=', '>=', '//', '**', '+=', '-=', '*=', '/=', '%=', '->', '<<', '>>', '|=', '&=', '^=',
  };
  static const _oneCharOps = {'=', '<', '>', '+', '-', '*', '/', '%', '|', '&', '^', '~', '@'};

  static List<Token> tokenize(String text, int line) {
    final tokens = <Token>[];
    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == ' ' || c == '\t') {
        i++;
        continue;
      }
      if (c == '#') break;

      // f-Strings: f"..." oder F'...'
      if ((c == 'f' || c == 'F') && i + 1 < text.length && (text[i + 1] == '"' || text[i + 1] == "'")) {
        final (content, end) = _readString(text, i + 1, line);
        tokens.add(Token(TokenType.fstring, content));
        i = end;
        continue;
      }
      // Roh-Strings: r"\d+" – Backslashes bleiben, wie sie sind
      if ((c == 'r' || c == 'R') && i + 1 < text.length && (text[i + 1] == '"' || text[i + 1] == "'")) {
        final (content, end) = _readString(text, i + 1, line, raw: true);
        tokens.add(Token(TokenType.string, content));
        i = end;
        continue;
      }
      if (_isDigit(c) || (c == '.' && i + 1 < text.length && _isDigit(text[i + 1]))) {
        final start = i;
        var isFloat = false;
        while (i < text.length && (_isDigit(text[i]) || text[i] == '_')) {
          i++;
        }
        if (i < text.length && text[i] == '.') {
          isFloat = true;
          i++;
          while (i < text.length && _isDigit(text[i])) {
            i++;
          }
        }
        if (i < text.length && (text[i] == 'e' || text[i] == 'E')) {
          isFloat = true;
          i++;
          if (i < text.length && (text[i] == '+' || text[i] == '-')) i++;
          while (i < text.length && _isDigit(text[i])) {
            i++;
          }
        }
        if (i < text.length && _isNameStart(text[i])) {
          throw PyError(line, 'SyntaxError',
              'Ein Name darf nicht mit einer Ziffer beginnen ("${text.substring(start, i + 1)}…").');
        }
        tokens.add(Token(isFloat ? TokenType.float : TokenType.integer,
            text.substring(start, i).replaceAll('_', '')));
        continue;
      }
      if (_isNameStart(c)) {
        final start = i;
        while (i < text.length && _isNamePart(text[i])) {
          i++;
        }
        tokens.add(Token(TokenType.name, text.substring(start, i)));
        continue;
      }
      if (c == '"' || c == "'") {
        final (content, end) = _readString(text, i, line);
        tokens.add(Token(TokenType.string, content));
        i = end;
        continue;
      }
      final single = switch (c) {
        '(' => TokenType.lparen,
        ')' => TokenType.rparen,
        '[' => TokenType.lbracket,
        ']' => TokenType.rbracket,
        '{' => TokenType.lbrace,
        '}' => TokenType.rbrace,
        ',' => TokenType.comma,
        ':' => TokenType.colon,
        '.' => TokenType.dot,
        _ => null,
      };
      if (single != null) {
        tokens.add(Token(single, c));
        i++;
        continue;
      }
      final three = i + 2 < text.length ? text.substring(i, i + 3) : '';
      final two = i + 1 < text.length ? text.substring(i, i + 2) : '';
      if (_threeCharOps.contains(three)) {
        tokens.add(Token(TokenType.op, three));
        i += 3;
      } else if (_twoCharOps.contains(two)) {
        tokens.add(Token(TokenType.op, two));
        i += 2;
      } else if (_oneCharOps.contains(c)) {
        tokens.add(Token(TokenType.op, c));
        i++;
      } else if (c == '“' || c == '”' || c == '„' || c == '‘' || c == '’') {
        throw PyError(line, 'SyntaxError',
            'Das Anführungszeichen $c versteht Python nicht. Benutze " oder \' von der Tastatur.');
      } else {
        throw PyError(line, 'SyntaxError', 'Das Zeichen "$c" versteht Python hier nicht.');
      }
    }
    return tokens;
  }

  /// Liest einen String ab dem Anführungszeichen bei [start].
  /// Gibt den Inhalt (mit aufgelösten Escapes) und die Position danach zurück.
  static (String, int) _readString(String text, int start, int line, {bool raw = false}) {
    final quote = text[start];
    final triple = text.startsWith(quote * 3, start);
    final b = StringBuffer();
    var i = start + (triple ? 3 : 1);
    while (i < text.length) {
      final c = text[i];
      if (triple) {
        if (text.startsWith(quote * 3, i)) return (b.toString(), i + 3);
      } else if (c == quote) {
        return (b.toString(), i + 1);
      } else if (c == '\n') {
        break;
      }
      if (c == '\\' && i + 1 < text.length && raw) {
        b.write(text.substring(i, i + 2));
        i += 2;
        continue;
      }
      if (c == '\\' && i + 1 < text.length) {
        final n = text[i + 1];
        b.write(switch (n) {
          'n' => '\n',
          't' => '\t',
          'r' => '\r',
          'b' => '\b',
          '\n' => '',
          '\\' => '\\',
          "'" => "'",
          '"' => '"',
          _ => '\\$n',
        });
        i += 2;
        continue;
      }
      b.write(c);
      i++;
    }
    throw PyError(line, 'SyntaxError',
        'Der Text wurde nicht beendet – es fehlt das schließende Anführungszeichen ${triple ? quote * 3 : quote}.');
  }

  static bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }

  static final _nameStart = RegExp(r'[A-Za-z_äöüÄÖÜß]');
  static bool _isNameStart(String c) => _nameStart.hasMatch(c);
  static bool _isNamePart(String c) => _isNameStart(c) || _isDigit(c);
}
