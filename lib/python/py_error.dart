/// Ein Python-Fehler mit Zeilennummer, Python-Fehlertyp und deutscher Erklärung.
class PyError implements Exception {
  const PyError(this.line, this.type, this.message);

  /// Zeilennummer (1-basiert).
  final int line;

  /// Python-Fehlertyp, z. B. `NameError` oder `IndentationError`.
  final String type;

  /// Deutsche Erklärung.
  final String message;

  /// z. B. "Zeile 3 – NameError: Die Variable "x" gibt es noch nicht."
  String get display => 'Zeile $line – $type: $message';

  @override
  String toString() => display;
}
