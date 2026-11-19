import '../python/interpreter.dart';
import 'exercise.dart';

/// Antwort des Spielers – je nach Aufgabentyp.
sealed class Answer {
  const Answer();
}

class FillAnswer extends Answer {
  const FillAnswer(this.inputs);
  final List<String> inputs;
}

class ChoiceAnswer extends Answer {
  const ChoiceAnswer(this.index);
  final int index;
}

class OrderAnswer extends Answer {
  const OrderAnswer(this.order);
  final List<int> order;
}

class CheckResult {
  const CheckResult({required this.correct, required this.message, this.run, this.incomplete = false});

  final bool correct;

  /// Antwort noch nicht vollständig (kostet kein Herz).
  final bool incomplete;

  /// Deutsche Rückmeldung: warum richtig oder was nicht passt.
  final String message;

  /// Ergebnis des Probelaufs mit der Antwort (falls ausgeführt).
  final RunResult? run;
}

abstract final class Checker {
  static const _interpreter = Interpreter(maxSteps: 2000);

  static CheckResult check(Exercise exercise, Answer answer) => switch ((exercise, answer)) {
    (FillExercise e, FillAnswer a) => _fill(e, a.inputs),
    (ChoiceExercise e, ChoiceAnswer a) => _choice(e, a.index),
    (OrderExercise e, OrderAnswer a) => _order(e, a.order),
    _ => throw ArgumentError('Antwort passt nicht zur Aufgabe'),
  };

  /// Vereinfacht eine Eingabe zum Vergleichen: Leerzeichen und Anführungszeichen.
  static String normalize(String s) => s
      .trim()
      .replaceAll('"', "'")
      .replaceAllMapped(RegExp(r"\s*([=+\-*/%<>!,:()\[\]{}])\s*"), (m) => m[1]!)
      .replaceAll(RegExp(r'\s+'), ' ');

  static CheckResult _fill(FillExercise e, List<String> inputs) {
    if (inputs.length != e.blankCount || inputs.any((i) => i.trim().isEmpty)) {
      return const CheckResult(correct: false, incomplete: true, message: 'Fülle zuerst alle Lücken aus.');
    }
    final exact = [
      for (var i = 0; i < e.blankCount; i++)
        e.answers[i].any((a) => normalize(a) == normalize(inputs[i])),
    ];
    final code = e.fill(inputs.map((i) => i.trim()).toList());
    final run = _interpreter.run(code);
    if (exact.every((x) => x)) {
      return CheckResult(correct: true, message: 'Genau richtig!', run: run);
    }
    if (run.error != null) {
      return CheckResult(correct: false, message: 'Mit deiner Antwort meldet Python einen Fehler:\n${run.error!.display}', run: run);
    }
    final expected = e.expectedOutput;
    if (expected != null && run.output == expected) {
      return CheckResult(correct: true, message: 'Richtig! Deine Lösung funktioniert auch.', run: run);
    }
    if (expected != null) {
      return CheckResult(
        correct: false,
        message: 'Dein Code gibt ${_quote(run.output)} aus, gesucht ist aber ${_quote(expected)}.',
        run: run,
      );
    }
    final wrong = [for (var i = 0; i < exact.length; i++) if (!exact[i]) i + 1];
    return CheckResult(
      correct: false,
      message: wrong.length == 1 && e.blankCount > 1
          ? 'Lücke ${wrong.first} passt noch nicht.'
          : 'Das passt hier noch nicht ganz.',
      run: run,
    );
  }

  static CheckResult _choice(ChoiceExercise e, int index) => index == e.correct
      ? const CheckResult(correct: true, message: 'Richtig!')
      : CheckResult(correct: false, message: 'Nicht ganz. Schau dir den Code nochmal Zeile für Zeile an.');

  static CheckResult _order(OrderExercise e, List<int> order) {
    if (order.length != e.lines.length) {
      return const CheckResult(correct: false, incomplete: true, message: 'Benutze alle Zeilen.');
    }
    final code = e.arrange(order);
    final run = _interpreter.run(code);
    final inOrder = [for (var i = 0; i < order.length; i++) order[i] == i].every((x) => x);
    if (inOrder || (run.error == null && run.output == e.expectedOutput)) {
      return CheckResult(correct: true, message: 'Perfekte Reihenfolge!', run: run);
    }
    if (run.error != null) {
      return CheckResult(correct: false, message: 'In dieser Reihenfolge meldet Python:\n${run.error!.display}', run: run);
    }
    return CheckResult(
      correct: false,
      message: 'In dieser Reihenfolge kommt ${_quote(run.output)} heraus, gesucht ist ${_quote(e.expectedOutput)}.',
      run: run,
    );
  }

  static String _quote(String s) => s.isEmpty ? '(nichts)' : '„${s.replaceAll('\n', ' ⏎ ')}“';
}
