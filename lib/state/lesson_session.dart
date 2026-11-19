import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exercises/checker.dart';
import '../exercises/exercise.dart';
import '../exercises/scoring.dart';
import 'providers.dart';

enum SessionStatus { answering, correct, wrong, revealed, finished }

class LessonSessionState {
  const LessonSessionState({
    required this.queue,
    this.position = 0,
    this.hearts = Scoring.hearts,
    this.xp = 0,
    this.combo = 0,
    this.status = SessionStatus.answering,
    this.lastCheck,
    this.attempt = 0,
    this.mistakes = 0,
    this.reward,
  });

  /// Fehlversuche bei der aktuellen Aufgabe (bestimmt, wie viel Robo verrät).
  final int mistakes;

  /// Reihenfolge der Aufgaben (Indizes); aufgedeckte Aufgaben kommen am Ende nochmal.
  final List<int> queue;
  final int position;
  final int hearts;
  final int xp;
  final int combo;
  final SessionStatus status;
  final CheckResult? lastCheck;

  /// Zählt hoch, wenn eine neue Aufgabe beginnt (setzt die Eingabefelder zurück).
  final int attempt;
  final LessonReward? reward;

  int get exerciseIndex => queue[position.clamp(0, queue.length - 1)];
  double get progress => queue.isEmpty ? 0 : position / queue.length;
  bool get isChecked => status == SessionStatus.correct || status == SessionStatus.wrong || status == SessionStatus.revealed;

  LessonSessionState copyWith({
    List<int>? queue,
    int? position,
    int? hearts,
    int? xp,
    int? combo,
    SessionStatus? status,
    CheckResult? lastCheck,
    bool clearCheck = false,
    int? attempt,
    int? mistakes,
    LessonReward? reward,
  }) => LessonSessionState(
    queue: queue ?? this.queue,
    position: position ?? this.position,
    hearts: hearts ?? this.hearts,
    xp: xp ?? this.xp,
    combo: combo ?? this.combo,
    status: status ?? this.status,
    lastCheck: clearCheck ? null : (lastCheck ?? this.lastCheck),
    attempt: attempt ?? this.attempt,
    mistakes: mistakes ?? this.mistakes,
    reward: reward ?? this.reward,
  );
}

/// Ablauf einer Lektion: prüfen, Herzen, XP, Lösung zeigen, Abschluss.
/// Herzen bestimmen nur die Sterne – bei vielen Fehlern gibt es mehr Tipps statt eines Neustarts.
class LessonSession extends Notifier<LessonSessionState> {
  LessonSession(this.lesson);

  final Lesson lesson;
  final _requeued = <int>{};

  @override
  LessonSessionState build() =>
      LessonSessionState(queue: List.generate(lesson.exercises.length, (i) => i));

  Exercise get current => lesson.exercises[state.exerciseIndex];

  void check(Answer answer) {
    if (state.status != SessionStatus.answering) return;
    final result = Checker.check(current, answer);
    if (result.correct) {
      final combo = state.combo + 1;
      state = state.copyWith(
        status: SessionStatus.correct,
        lastCheck: result,
        combo: combo,
        xp: state.xp + Scoring.xpFor(combo),
      );
    } else if (result.incomplete) {
      // unvollständig – kein Herz abziehen
      state = state.copyWith(lastCheck: result);
    } else {
      state = state.copyWith(
        status: SessionStatus.wrong,
        lastCheck: result,
        combo: 0,
        hearts: (state.hearts - 1).clamp(0, Scoring.hearts),
        mistakes: state.mistakes + 1,
      );
    }
  }

  /// Nach einer falschen Antwort dieselbe Aufgabe nochmal versuchen.
  void retry() {
    if (state.status != SessionStatus.wrong) return;
    state = state.copyWith(status: SessionStatus.answering, clearCheck: true);
  }

  /// Lösung anzeigen (ohne XP). Die Aufgabe kommt am Ende nochmal dran.
  void reveal() {
    if (state.status != SessionStatus.wrong && state.status != SessionStatus.answering) return;
    var queue = state.queue;
    if (_requeued.add(state.exerciseIndex)) queue = [...queue, state.exerciseIndex];
    state = state.copyWith(status: SessionStatus.revealed, combo: 0, queue: queue);
  }

  void next() {
    if (!state.isChecked) return;
    final position = state.position + 1;
    if (position >= state.queue.length) {
      final stars = Scoring.starsFor(state.hearts);
      final reward = ref.read(profileProvider.notifier).completeLesson(lessonId: lesson.id, stars: stars, xp: state.xp);
      state = state.copyWith(position: position, status: SessionStatus.finished, reward: reward, clearCheck: true);
      return;
    }
    state = state.copyWith(
      position: position,
      status: SessionStatus.answering,
      clearCheck: true,
      attempt: state.attempt + 1,
      mistakes: 0,
    );
  }

  void restart() {
    _requeued.clear();
    state = LessonSessionState(
      queue: List.generate(lesson.exercises.length, (i) => i),
      attempt: state.attempt + 1,
    );
  }
}

final lessonSessionProvider = NotifierProvider.family<LessonSession, LessonSessionState, Lesson>(
  LessonSession.new,
  isAutoDispose: true,
);
