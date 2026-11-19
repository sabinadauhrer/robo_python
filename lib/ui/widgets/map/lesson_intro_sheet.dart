import 'package:flutter/material.dart';

import '../../../exercises/exercise.dart';
import '../../../exercises/outfits.dart';
import '../../lesson_icons.dart';
import '../../theme.dart';
import '../kawaii/mascot_bubble.dart';

/// Kurze Einführung ins Thema, bevor die Aufgaben beginnen.
Future<bool?> showLessonIntro(BuildContext context, Lesson lesson, Outfit outfit, int stars) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) {
      final theme = Theme.of(context);
      final counts = <String, int>{};
      for (final e in lesson.exercises) {
        final label = switch (e) {
          FillExercise() => 'Lücke füllen',
          ChoiceExercise() => 'Was passiert?',
          OrderExercise() => 'Reihenfolge',
        };
        counts[label] = (counts[label] ?? 0) + 1;
      }
      return SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(lessonIcon(lesson.icon), color: AppColors.pinkDeep),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Insel ${lesson.order}: ${lesson.title}', style: theme.textTheme.headlineSmall)),
                  ]),
                  const SizedBox(height: 14),
                  MascotBubble(text: lesson.intro, robotSize: 64, outfit: outfit),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final e in counts.entries) Chip(label: Text('${e.value}× ${e.key}')),
                    const Chip(avatar: Icon(Icons.favorite_rounded, color: AppColors.pinkDeep, size: 18), label: Text('3 Herzen')),
                  ]),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('start-lesson'),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(stars > 0 ? 'Nochmal spielen' : "Los geht's"),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
