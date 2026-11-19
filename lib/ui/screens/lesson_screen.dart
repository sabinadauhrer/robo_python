import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sfx.dart';
import '../../audio/sound_player.dart';
import '../../exercises/checker.dart';
import '../../exercises/exercise.dart';
import '../../state/lesson_session.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/lesson/choice_exercise_view.dart';
import '../widgets/lesson/feedback_bar.dart';
import '../widgets/lesson/fill_exercise_view.dart';
import '../widgets/lesson/lesson_end_views.dart';
import '../widgets/lesson/lesson_top_bar.dart';
import '../widgets/lesson/order_exercise_view.dart';
import '../widgets/lesson/robo_explain_card.dart';
import '../widgets/runner/trace_runner.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  static const wideBreakpoint = 980.0;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Answer? _answer;
  String? _code;
  int? _selectedLine;
  bool _showRunner = false;
  final _runnerKey = GlobalKey();

  void _resetForNewExercise() {
    _answer = null;
    _code = null;
    _selectedLine = null;
    _showRunner = false;
  }

  void _openRunner() {
    setState(() => _showRunner = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _runnerKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  void _check() {
    final answer = _answer;
    if (answer == null) return;
    ref.read(lessonSessionProvider(widget.lesson).notifier).check(answer);
  }

  @override
  Widget build(BuildContext context) {
    final provider = lessonSessionProvider(widget.lesson);
    final state = ref.watch(provider);
    final session = ref.read(provider.notifier);
    final outfit = ref.watch(profileProvider.select((p) => p.outfit));

    ref.listen(provider.select((s) => s.attempt), (_, _) => setState(_resetForNewExercise));
    ref.listen(provider.select((s) => s.status), (previous, status) {
      final sfx = switch (status) {
        SessionStatus.correct => Sfx.correct,
        SessionStatus.wrong => Sfx.wrong,
        SessionStatus.finished => Sfx.success,
        SessionStatus.failed => Sfx.error,
        _ => null,
      };
      if (previous != status) playSfx(ref, sfx);
    });

    if (state.status == SessionStatus.finished) {
      return Scaffold(
        body: SafeArea(
          child: LessonCompleteView(
            reward: state.reward!,
            outfit: outfit,
            onDone: () => Navigator.of(context).pop(),
            onRepeat: session.restart,
          ),
        ),
      );
    }
    if (state.status == SessionStatus.failed) {
      return Scaffold(
        body: SafeArea(child: LessonFailedView(onRetry: session.restart, onDone: () => Navigator.of(context).pop())),
      );
    }

    final exercise = widget.lesson.exercises[state.exerciseIndex];
    final runnable = _runnableCode(exercise, state);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: LessonTopBar(
                  progress: state.progress,
                  hearts: state.hearts,
                  combo: state.combo,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= LessonScreen.wideBreakpoint;
                  final exerciseWidget = _exerciseView(exercise, state);
                  final explain = RoboExplainCard(
                    exercise: exercise,
                    selectedLine: _selectedLine,
                    outfit: outfit,
                    onCloseNote: () => setState(() => _selectedLine = null),
                  );
                  final runner = _showRunner && runnable != null
                      ? KeyedSubtree(key: _runnerKey, child: TraceRunner(code: runnable))
                      : null;
                  final header = _TaskHeader(exercise: exercise);
                  if (!wide) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        header,
                        const SizedBox(height: 12),
                        explain,
                        const SizedBox(height: 16),
                        exerciseWidget,
                        if (runner != null) ...[const SizedBox(height: 16), runner],
                      ],
                    );
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 8, 24),
                              children: [header, const SizedBox(height: 16), exerciseWidget],
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
                              children: [
                                explain,
                                const SizedBox(height: 16),
                                runner ?? _RunnerTeaser(onOpen: runnable == null ? null : _openRunner, isChoice: exercise is ChoiceExercise),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FeedbackBar(
        state: state,
        exercise: exercise,
        canCheck: _answer != null,
        onCheck: _check,
        onRetry: session.retry,
        onReveal: session.reveal,
        onNext: session.next,
        onShowRun: runnable == null || _showRunner ? null : _openRunner,
      ),
    );
  }

  /// Code für den Probelauf – bei Auswahl-Aufgaben erst nach dem Antworten.
  String? _runnableCode(Exercise exercise, LessonSessionState state) {
    if (exercise is ChoiceExercise) return state.isChecked ? exercise.code : null;
    if (state.status == SessionStatus.revealed) return exercise is FillExercise ? exercise.fill(exercise.solution) : exercise.displayCode;
    return _code;
  }

  Widget _exerciseView(Exercise exercise, LessonSessionState state) {
    final key = ValueKey('${state.attempt}-${state.exerciseIndex}');
    void onChanged(Answer? answer, String? code) {
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _code = code;
      });
    }

    void onLineTap(int line) => setState(() => _selectedLine = _selectedLine == line ? null : line);

    return switch (exercise) {
      FillExercise() => FillExerciseView(
        key: key,
        exercise: exercise,
        status: state.status,
        selectedLine: _selectedLine,
        onLineTap: onLineTap,
        onChanged: onChanged,
        onSubmit: () => state.status == SessionStatus.answering ? _check() : null,
      ),
      ChoiceExercise() => ChoiceExerciseView(
        key: key,
        exercise: exercise,
        status: state.status,
        selectedLine: _selectedLine,
        onLineTap: onLineTap,
        onChanged: onChanged,
      ),
      OrderExercise() => OrderExerciseView(
        key: key,
        exercise: exercise,
        status: state.status,
        seed: widget.lesson.id.hashCode + state.exerciseIndex,
        onChanged: onChanged,
      ),
    };
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String label, IconData icon, Color color) = switch (exercise) {
      FillExercise() => ('Lücke füllen', Icons.edit_rounded, AppColors.butter),
      ChoiceExercise() => ('Was passiert?', Icons.quiz_rounded, AppColors.sky),
      OrderExercise() => ('Reihenfolge', Icons.reorder_rounded, AppColors.mint),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelLarge),
          ]),
        ),
        const SizedBox(height: 8),
        Text(exercise.task, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.3)),
      ],
    );
  }
}

class _RunnerTeaser extends StatelessWidget {
  const _RunnerTeaser({required this.onOpen, required this.isChoice});

  final VoidCallback? onOpen;
  final bool isChoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lavender, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.play_circle_rounded, color: AppColors.lavenderDeep),
            const SizedBox(width: 6),
            Text('Probelauf', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 6),
          Text(
            onOpen != null
                ? 'Lass den Code Schritt für Schritt laufen: Du siehst, welche Zeile gerade dran ist, was in den Variablen steckt und was ausgegeben wird.'
                : isChoice
                ? 'Nach deiner Antwort kannst du hier Schritt für Schritt ansehen, warum der Code das tut.'
                : 'Fülle zuerst alles aus – dann kannst du deinen Code hier Schritt für Schritt ausprobieren, bevor du prüfst.',
            style: theme.textTheme.bodyMedium,
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onOpen,
              style: FilledButton.styleFrom(backgroundColor: AppColors.lavenderDeep),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Probelauf starten'),
            ),
          ],
        ],
      ),
    );
  }
}
