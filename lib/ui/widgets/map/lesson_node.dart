import 'package:flutter/material.dart';

import '../../../exercises/exercise.dart';
import '../../lesson_icons.dart';
import '../../theme.dart';
import '../common/star_row.dart';

/// Eine Insel auf der Karte.
class LessonNode extends StatelessWidget {
  const LessonNode({
    super.key,
    required this.lesson,
    required this.stars,
    required this.locked,
    required this.isNext,
    required this.onTap,
  });

  final Lesson lesson;
  final int stars;
  final bool locked;

  /// Die Insel, die als Nächstes dran ist (wird hervorgehoben).
  final bool isNext;
  final VoidCallback onTap;

  static const size = 78.0;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.pastels[(lesson.order - 1) % AppColors.pastels.length];
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${lesson.title}${locked ? ', gesperrt' : ', $stars von 3 Sternen'}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isNext ? 1.1 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: locked ? const Color(0xFFEDE6EA) : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNext ? AppColors.pinkDeep : Colors.white,
                        width: isNext ? 5 : 4,
                      ),
                      boxShadow: locked ? null : softShadow(color),
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : lessonIcon(lesson.icon),
                      size: 36,
                      color: locked ? AppColors.inkSoft : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Schild unter der Insel (verdeckt auch die gepunktete Linie)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!locked) StarRow(stars: stars, size: 18),
                      Text(
                        lesson.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: locked ? AppColors.inkSoft : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
