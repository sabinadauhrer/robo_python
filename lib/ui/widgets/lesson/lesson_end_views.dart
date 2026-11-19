import 'package:flutter/material.dart';

import '../../../exercises/outfits.dart';
import '../../../state/providers.dart';
import '../../theme.dart';
import '../kawaii/kawaii_coin.dart';
import '../kawaii/kawaii_robot.dart';

/// Lektion geschafft: Sterne, XP, Münzen, Serie.
class LessonCompleteView extends StatelessWidget {
  const LessonCompleteView({super.key, required this.reward, required this.outfit, required this.onDone, required this.onRepeat});

  final LessonReward reward;
  final Outfit outfit;
  final VoidCallback onDone;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: KawaiiRobot(mood: RobotMood.happy, size: 140, outfit: outfit),
              ),
              const SizedBox(height: 12),
              Text('Insel geschafft!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Semantics(
                label: '${reward.stars} von 3 Sternen',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + i * 250),
                        curve: Interval(i * 0.3, 1, curve: Curves.elasticOut),
                        builder: (context, t, child) => Transform.scale(scale: t, child: child),
                        child: Icon(
                          i < reward.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < reward.stars ? AppColors.star : AppColors.cardBorder,
                          size: i == 1 ? 72 : 58,
                        ),
                      ),
                  ],
                ),
              ),
              if (reward.stars < 3)
                Text('Jedes übrige Herz ist ein Stern. Schaffst du alle 3?', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _RewardTile(icon: const Icon(Icons.star_rounded, color: AppColors.star, size: 30), value: '+${reward.xp}', label: 'XP'),
                  _RewardTile(icon: const SizedBox(width: 30, height: 30, child: KawaiiCoin()), value: '+${reward.coins}', label: 'Münzen'),
                  _RewardTile(
                    icon: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF8A3D), size: 30),
                    value: '${reward.streak}',
                    label: reward.streak == 1 ? 'Tag Serie' : 'Tage Serie',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const Key('done'),
                onPressed: onDone,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Zur Karte'),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 54)),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRepeat, child: const Text('Nochmal üben')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.icon, required this.value, required this.label});

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.cardBorder, width: 2),
      boxShadow: softShadow(),
    ),
    child: Column(children: [
      icon,
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

/// Alle Herzen weg.
class LessonFailedView extends StatelessWidget {
  const LessonFailedView({super.key, required this.onRetry, required this.onDone});

  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KawaiiRobot(mood: RobotMood.dizzy, size: 130),
            const SizedBox(height: 12),
            Text('Oh nein, keine Herzen mehr!', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Kein Problem – Fehler gehören zum Lernen dazu. Beim nächsten Mal kennst du die Aufgaben schon!',
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(key: const Key('restart'), onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Nochmal versuchen')),
            const SizedBox(height: 8),
            TextButton(onPressed: onDone, child: const Text('Zur Karte')),
          ],
        ),
      ),
    );
  }
}
