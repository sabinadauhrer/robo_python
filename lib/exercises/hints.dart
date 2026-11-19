import 'exercise.dart';

/// Tipp-Leiter: Je öfter man bei einer Aufgabe danebenliegt, desto mehr verrät Robo.
/// Niemand muss eine Insel von vorn beginnen – man bekommt einfach mehr Hilfe.
abstract final class Hints {
  /// Ab so vielen Fehlern bei einer Aufgabe bietet Robo die Lösung an.
  static const offerSolutionAfter = 3;

  /// Hilfe nach dem [mistakes]-ten Fehler (1, 2, 3, …) bei [exercise].
  static String forMistake(Exercise exercise, int mistakes) {
    if (mistakes <= 1) {
      if (exercise.hint.isNotEmpty) return 'Tipp: ${exercise.hint}';
      return 'Tipp: Lies Robos Erklärung oben noch einmal – und tippe auf die Zeilen mit ?, dort steht mehr.';
    }
    if (mistakes == 2) return 'Großer Tipp: ${_bigHint(exercise)}';
    return 'Kein Problem, das ist knifflig! Tippe auf „Lösung zeigen“ – Robo erklärt sie dir. '
        'Die Aufgabe kommt am Ende der Insel noch einmal, dann klappt es bestimmt.';
  }

  static String _bigHint(Exercise e) => switch (e) {
    FillExercise() => _fillHint(e),
    ChoiceExercise() => e.isOutputQuestion
        ? 'Tippe auf „Warum? Ansehen“: Der Probelauf spielt den Code Zeile für Zeile ab und zeigt dir die Ausgabe.'
        : 'Gehe die Antworten einzeln durch und schließe aus, was sicher nicht stimmt. ${e.hint}'.trim(),
    OrderExercise() => 'Die erste Zeile ist: ${e.lines.first.trim()}',
  };

  static String _fillHint(FillExercise e) {
    final parts = <String>[];
    for (var i = 0; i < e.answers.length; i++) {
      final solution = e.answers[i].first;
      final shown = solution.length <= 2 ? solution.substring(0, 1) : solution.substring(0, (solution.length / 3).ceil());
      final label = e.answers.length == 1 ? 'Die Lücke' : 'Lücke ${i + 1}';
      parts.add('$label beginnt mit „$shown…“ (${solution.length} Zeichen)');
    }
    return '${parts.join(', ')}.';
  }
}
