enum TokenType {
  integer,
  float,
  string,
  fstring,
  name,
  op,
  lparen,
  rparen,
  lbracket,
  rbracket,
  lbrace,
  rbrace,
  comma,
  colon,
  dot,
}

class Token {
  const Token(this.type, this.text);

  final TokenType type;

  /// Bei Strings: der Inhalt (Escapes bereits aufgelöst), sonst der Quelltext.
  final String text;

  bool isOp(String op) => type == TokenType.op && text == op;
  bool isName(String name) => type == TokenType.name && text == name;

  bool get opens =>
      type == TokenType.lparen || type == TokenType.lbracket || type == TokenType.lbrace;
  bool get closes =>
      type == TokenType.rparen || type == TokenType.rbracket || type == TokenType.rbrace;

  /// Text, wie er im Code stand (für Beschreibungen).
  String get source => switch (type) {
    TokenType.string => '"$text"',
    TokenType.fstring => 'f"$text"',
    _ => text,
  };

  @override
  String toString() => '$type($text)';
}

/// Setzt Tokens wieder zu lesbarem Code zusammen, z. B. für "Bedingung x > 3".
String tokensToSource(Iterable<Token> tokens) {
  final b = StringBuffer();
  Token? prev;
  for (final t in tokens) {
    if (prev != null) {
      final noSpaceBefore = t.closes ||
          t.type == TokenType.comma ||
          t.type == TokenType.colon ||
          t.type == TokenType.dot ||
          ((t.type == TokenType.lparen || t.type == TokenType.lbracket) &&
              (prev.type == TokenType.name || prev.closes || prev.type == TokenType.string));
      final noSpaceAfter = prev.opens || prev.type == TokenType.dot;
      if (!noSpaceBefore && !noSpaceAfter) b.write(' ');
    }
    b.write(t.source);
    prev = t;
  }
  return b.toString();
}
