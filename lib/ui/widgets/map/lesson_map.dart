import 'dart:math';

import 'package:flutter/material.dart';

import '../../../exercises/exercise.dart';
import '../../theme.dart';
import 'lesson_node.dart';

/// Geschwungener Pfad mit allen Inseln.
class LessonMap extends StatelessWidget {
  const LessonMap({
    super.key,
    required this.lessons,
    required this.stars,
    required this.isUnlocked,
    required this.onOpen,
    required this.onLocked,
  });

  final List<Lesson> lessons;
  final Map<String, int> stars;
  final bool Function(int index) isUnlocked;
  final ValueChanged<Lesson> onOpen;

  /// Tipp auf eine gesperrte Insel.
  final ValueChanged<Lesson> onLocked;

  static const rowHeight = 150.0;

  /// Platz für ein Kapitel-Schild über der ersten Insel eines Kapitels.
  static const chapterHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(constraints.maxWidth, 640.0);
        final amplitude = max(0.0, (width - 160) / 2 - 10).clamp(0.0, 180.0);
        // Wie viele Kapitel-Schilder stehen bis einschließlich Insel i?
        final chapterStarts = <int>[];
        final chaptersBefore = <int>[];
        for (var i = 0; i < lessons.length; i++) {
          final starts = lessons[i].chapter != null && (i == 0 || lessons[i - 1].chapter != lessons[i].chapter);
          if (starts) chapterStarts.add(i);
          chaptersBefore.add(chapterStarts.length);
        }
        Offset center(int i) =>
            Offset(width / 2 + sin(i * 1.1) * amplitude, 60 + i * rowHeight + chaptersBefore[i] * chapterHeight);
        final next = lessons.indexWhere((l) => (stars[l.id] ?? 0) == 0);
        final height = lessons.isEmpty ? 0.0 : center(lessons.length - 1).dy + rowHeight - 20;
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PathPainter([for (var i = 0; i < lessons.length; i++) center(i)], doneUntil: next < 0 ? lessons.length : next),
                  ),
                ),
                for (final (n, i) in chapterStarts.indexed)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: center(i).dy - LessonNode.size / 2 - chapterHeight + 4,
                    child: Center(
                      child: _ChapterBanner(
                        number: n + 1,
                        title: lessons[i].chapter!,
                        done: lessons.where((l) => l.chapter == lessons[i].chapter).every((l) => (stars[l.id] ?? 0) > 0),
                      ),
                    ),
                  ),
                for (var i = 0; i < lessons.length; i++)
                  Positioned(
                    left: center(i).dx - 75,
                    top: center(i).dy - LessonNode.size / 2,
                    child: LessonNode(
                      lesson: lessons[i],
                      stars: stars[lessons[i].id] ?? 0,
                      locked: !isUnlocked(i),
                      isNext: i == next,
                      onTap: () => isUnlocked(i) ? onOpen(lessons[i]) : onLocked(lessons[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Schild mit Kapitelnummer und -name.
class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({required this.number, required this.title, required this.done});

  final int number;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: done ? AppColors.mint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Kapitel $number · ', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.inkSoft)),
          Flexible(
            child: Text(title, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
          ),
          if (done) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.ink),
          ],
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.points, {required this.doneUntil});

  final List<Offset> points;
  final int doneUntil;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final paint = Paint()
        ..color = i < doneUntil ? AppColors.pink : AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      // gepunktete Kurve
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + 70, b.dx, b.dy - 70, b.dx, b.dy);
      for (final metric in path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 22) {
          final seg = metric.extractPath(d, min(d + 10, metric.length));
          canvas.drawPath(seg, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.doneUntil != doneUntil || old.points.length != points.length;
}
