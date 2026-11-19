import 'py_error.dart';

enum StepKind { start, assign, print, condition, loop, call, giveBack, define, other, error }

/// Eine Variable in einer Momentaufnahme.
class VarView {
  const VarView({
    required this.name,
    required this.repr,
    required this.typeName,
    required this.changed,
    this.scope,
  });

  final String name;

  /// Wert so dargestellt, wie Python ihn zeigen würde.
  final String repr;
  final String typeName;

  /// Hat sich die Variable in diesem Schritt geändert (oder ist neu)?
  final bool changed;

  /// `null` = global, sonst Name der Funktion.
  final String? scope;
}

/// Momentaufnahme NACH einem Schritt.
class TraceStep {
  const TraceStep({
    required this.line,
    required this.kind,
    required this.description,
    required this.variables,
    required this.output,
  });

  /// Zeile (1-basiert); `null` beim Start.
  final int? line;
  final StepKind kind;

  /// Deutsche Erklärung, was in diesem Schritt passiert ist.
  final String description;
  final List<VarView> variables;

  /// Gesamte bisherige Ausgabe.
  final String output;
}

class RunResult {
  const RunResult({required this.trace, this.error, this.isSyntaxError = false});

  final List<TraceStep> trace;
  final PyError? error;

  /// Das Programm konnte wegen eines Schreibfehlers gar nicht starten.
  final bool isSyntaxError;

  bool get hasError => error != null;

  /// Gesamte Ausgabe ohne abschließenden Zeilenumbruch.
  String get output {
    final o = trace.last.output;
    return o.endsWith('\n') ? o.substring(0, o.length - 1) : o;
  }
}
