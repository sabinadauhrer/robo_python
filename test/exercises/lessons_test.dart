import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:robo_python/data/lesson_repository.dart';
import 'package:robo_python/exercises/checker.dart';
import 'package:robo_python/exercises/exercise.dart';
import 'package:robo_python/python/interpreter.dart';

/// Prüft ALLE Aufgaben mit dem eigenen Interpreter. Die erwarteten Ausgaben
/// stammen von echtem Python (tool/lessons_source.py).
void main() {
  final lessons = LessonRepository.parse(Directory('assets/lessons')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => f.readAsStringSync()));
  const interpreter = Interpreter();

  test('20 Lektionen mit eindeutigen IDs und fortlaufender Reihenfolge', () {
    expect(lessons, hasLength(20));
    expect(lessons.map((l) => l.id).toSet(), hasLength(20));
    expect(lessons.map((l) => l.order), List.generate(20, (i) => i + 1));
    expect(lessons.every((l) => l.exercises.length >= 5), isTrue);
  });

  for (final lesson in lessons) {
    group(lesson.title, () {
      for (var i = 0; i < lesson.exercises.length; i++) {
        final e = lesson.exercises[i];
        test('Aufgabe ${i + 1} (${e.runtimeType})', () {
          final lineCount = e.displayCode.split('\n').length;
          for (final n in e.notes.keys) {
            expect(n, inInclusiveRange(1, lineCount), reason: 'Notiz für Zeile $n');
          }
          expect(e.explain, isNotEmpty);
          switch (e) {
            case FillExercise():
              expect(e.answers, hasLength(e.blankCount));
              final check = Checker.check(e, FillAnswer(e.solution));
              expect(check.correct, isTrue, reason: check.message);
              expect(check.run!.error, isNull, reason: check.run!.error?.display);
              if (e.expectedOutput != null) expect(check.run!.output, e.expectedOutput);
              for (var b = 0; b < e.blankCount; b++) {
                for (final alt in e.answers[b]) {
                  final inputs = [...e.solution]..[b] = alt;
                  expect(Checker.check(e, FillAnswer(inputs)).correct, isTrue, reason: 'Alternative $alt');
                }
              }
              expect(Checker.check(e, FillAnswer(List.filled(e.blankCount, 'xyz'))).correct, isFalse);
            case ChoiceExercise():
              expect(e.correct, inInclusiveRange(0, e.options.length - 1));
              final run = interpreter.run(e.code);
              if (e.isOutputQuestion) {
                expect(run.error, isNull, reason: run.error?.display);
                expect(run.output, e.options[e.correct]);
              }
              final mentioned = RegExp(r'(\w+Error|StopIteration)').firstMatch(e.options[e.correct])?[1];
              if (mentioned != null) expect(run.error?.type, mentioned);
            case OrderExercise():
              final check = Checker.check(e, OrderAnswer(List.generate(e.lines.length, (i) => i)));
              expect(check.correct, isTrue);
              expect(check.run!.output, e.expectedOutput);
              final reversed = List.generate(e.lines.length, (i) => e.lines.length - 1 - i);
              expect(Checker.check(e, OrderAnswer(reversed)).correct, isFalse);
          }
        });
      }
    });
  }
}
