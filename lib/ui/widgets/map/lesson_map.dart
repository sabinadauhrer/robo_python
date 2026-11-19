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
  });

  final List<Lesson> lessons;
  final Map<String, int> stars;
  final bool Function(int index) isUnlocked;
  final ValueChanged<Lesson> onOpen;

  static const rowHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(constraints.maxWidth, 640.0);
        final amplitude = max(0.0, (width - 160) / 2 - 10).clamp(0.0, 180.0);
        Offset center(int i) => Offset(width / 2 + sin(i * 1.1) * amplitude, 60 + i * rowHeight);
        final next = lessons.indexWhere((l) => (stars[l.id] ?? 0) == 0);
        return Center(
          child: SizedBox(
            width: width,
            height: lessons.length * rowHeight + 40,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PathPainter([for (var i = 0; i < lessons.length; i++) center(i)], doneUntil: next < 0 ? lessons.length : next),
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
                      onTap: () => onOpen(lessons[i]),
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
