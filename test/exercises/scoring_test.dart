import 'package:flutter_test/flutter_test.dart';
import 'package:robo_python/exercises/checker.dart';
import 'package:robo_python/exercises/exercise.dart';
import 'package:robo_python/exercises/scoring.dart';

void main() {
  test('XP mit Combo-Bonus', () {
    expect(Scoring.xpFor(1), 10);
    expect(Scoring.xpFor(3), 14);
    expect(Scoring.xpFor(50), 20);
  });

  test('Sterne entsprechen den übrigen Herzen', () {
    expect(Scoring.starsFor(3), 3);
    expect(Scoring.starsFor(1), 1);
  });

  test('Tages-Serie', () {
    final today = DateTime(2026, 11, 19, 15);
    expect(Scoring.nextStreak(lastPlayed: null, today: today, streak: 0), 1);
    expect(Scoring.nextStreak(lastPlayed: DateTime(2026, 11, 18, 23), today: today, streak: 4), 5);
    expect(Scoring.nextStreak(lastPlayed: DateTime(2026, 11, 19, 8), today: today, streak: 4), 4);
    expect(Scoring.nextStreak(lastPlayed: DateTime(2026, 11, 16), today: today, streak: 4), 1);
    expect(Scoring.visibleStreak(lastPlayed: DateTime(2026, 11, 16), today: today, streak: 4), 0);
  });

  group('Lückentext prüfen', () {
    const e = FillExercise(
      task: 't', explain: 'e', notes: {}, hint: '',
      code: 'x = ___\nprint(x * 2)', answers: [['5']], expectedOutput: '10',
    );

    test('richtige Antwort, auch mit Leerzeichen', () {
      expect(Checker.check(e, const FillAnswer([' 5 '])).correct, isTrue);
    });

    test('andere Antwort mit gleicher Ausgabe zählt auch', () {
      final r = Checker.check(e, const FillAnswer(['2 + 3']));
      expect(r.correct, isTrue);
      expect(r.message, contains('funktioniert auch'));
    });

    test('falsche Ausgabe wird erklärt', () {
      final r = Checker.check(e, const FillAnswer(['4']));
      expect(r.correct, isFalse);
      expect(r.message, contains('„8“'));
    });

    test('Python-Fehler wird gezeigt', () {
      final r = Checker.check(e, const FillAnswer(['y']));
      expect(r.message, contains('NameError'));
    });

    test('leere Lücke', () {
      expect(Checker.check(e, const FillAnswer([''])).message, contains('Fülle zuerst'));
    });
  });
}
