import 'package:flutter/material.dart';

import '../../../exercises/exercise.dart';
import '../../../exercises/hints.dart';
import '../../../exercises/scoring.dart';
import '../../../state/lesson_session.dart';
import '../../theme.dart';

/// Untere Leiste: "Prüfen" – danach Rückmeldung mit Erklärung und den nächsten Schritten.
class FeedbackBar extends StatelessWidget {
  const FeedbackBar({
    super.key,
    required this.state,
    required this.exercise,
    required this.canCheck,
    required this.onCheck,
    required this.onRetry,
    required this.onReveal,
    required this.onNext,
    required this.onShowRun,
  });

  final LessonSessionState state;
  final Exercise exercise;
  final bool canCheck;
  final VoidCallback onCheck;
  final VoidCallback onRetry;
  final VoidCallback onReveal;
  final VoidCallback onNext;

  /// Öffnet den Probelauf (null, wenn nicht möglich).
  final VoidCallback? onShowRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = state.status;
    final check = state.lastCheck;

    final (Color bg, Color accent) = switch (status) {
      SessionStatus.correct => (const Color(0xFFE4F8EF), AppColors.mintDeep),
      SessionStatus.wrong => (const Color(0xFFFFE8EE), AppColors.error),
      SessionStatus.revealed => (const Color(0xFFF1EBFF), AppColors.lavenderDeep),
      _ => (Colors.white, AppColors.pinkDeep),
    };

    Widget button(String label, VoidCallback? onTap, {bool primary = true, IconData? icon, Key? key}) {
      final style = primary ? FilledButton.styleFrom(backgroundColor: accent, minimumSize: const Size(140, 52)) : null;
      return primary
          ? FilledButton.icon(key: key, style: style, onPressed: onTap, icon: Icon(icon ?? Icons.arrow_forward_rounded), label: Text(label))
          : OutlinedButton.icon(key: key, onPressed: onTap, icon: Icon(icon ?? Icons.refresh_rounded), label: Text(label));
    }

    final List<Widget> content;
    final List<Widget> actions;
    switch (status) {
      case SessionStatus.correct:
        content = [
          Row(children: [
            Icon(Icons.check_circle_rounded, color: accent, size: 30),
            const SizedBox(width: 8),
            Text('Super!', style: theme.textTheme.titleLarge?.copyWith(color: accent)),
            const SizedBox(width: 10),
            _Chip('+${Scoring.xpFor(state.combo)} XP', AppColors.butter),
            if (state.combo >= 2) ...[const SizedBox(width: 6), _Chip('${state.combo}er-Serie', AppColors.peach)],
          ]),
          if (check != null) _text(theme, check.message),
          if (exercise.why != null) _text(theme, exercise.why!),
        ];
        actions = [
          if (onShowRun != null) button('Schritt für Schritt', onShowRun, primary: false, icon: Icons.play_circle_outline_rounded),
          button('Weiter', onNext, key: const Key('next')),
        ];
      case SessionStatus.wrong:
        final offerSolution = state.mistakes >= Hints.offerSolutionAfter;
        content = [
          Row(children: [
            Icon(Icons.heart_broken_rounded, color: accent, size: 30),
            const SizedBox(width: 8),
            Text('Noch nicht ganz', style: theme.textTheme.titleLarge?.copyWith(color: accent)),
          ]),
          if (check != null) _text(theme, check.message),
          _HintBox(key: const Key('hint'), text: Hints.forMistake(exercise, state.mistakes)),
        ];
        actions = [
          if (onShowRun != null) button('Warum? Ansehen', onShowRun, primary: false, icon: Icons.play_circle_outline_rounded),
          if (offerSolution) ...[
            button('Nochmal', onRetry, primary: false, icon: Icons.refresh_rounded, key: const Key('retry')),
            button('Lösung zeigen', onReveal, icon: Icons.visibility_rounded, key: const Key('reveal')),
          ] else ...[
            button('Lösung zeigen', onReveal, primary: false, icon: Icons.visibility_rounded, key: const Key('reveal')),
            button('Nochmal', onRetry, icon: Icons.refresh_rounded, key: const Key('retry')),
          ],
        ];
      case SessionStatus.revealed:
        content = [
          Row(children: [
            Icon(Icons.visibility_rounded, color: accent, size: 28),
            const SizedBox(width: 8),
            Text('So geht’s', style: theme.textTheme.titleLarge?.copyWith(color: accent)),
          ]),
          _text(theme, exercise.why ?? 'Schau dir die Lösung oben an – Robo erklärt daneben, warum sie so ist. Diese Aufgabe kommt am Ende nochmal.'),
        ];
        actions = [
          if (onShowRun != null) button('Schritt für Schritt', onShowRun, primary: false, icon: Icons.play_circle_outline_rounded),
          button('Weiter', onNext, key: const Key('next')),
        ];
      default:
        content = [
          if (check != null && check.incomplete) _text(theme, check.message),
        ];
        actions = [
          if (onShowRun != null) button('Probelauf', onShowRun, primary: false, icon: Icons.play_circle_outline_rounded),
          button('Prüfen', canCheck ? onCheck : null, icon: Icons.check_rounded, key: const Key('check')),
        ];
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.35), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...content,
                  if (content.isNotEmpty) const SizedBox(height: 10),
                  Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Semantics(liveRegion: true, child: Text(text, style: theme.textTheme.bodyLarge)),
  );
}

/// Robos Tipp nach einem Fehler – wird mit jedem Fehlversuch genauer.
class _HintBox extends StatelessWidget {
  const _HintBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.butter, borderRadius: BorderRadius.circular(14)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_rounded, color: AppColors.ink),
        const SizedBox(width: 8),
        Expanded(child: Semantics(liveRegion: true, child: Text(text, style: Theme.of(context).textTheme.bodyLarge))),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
