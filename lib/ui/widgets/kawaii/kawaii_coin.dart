import 'package:flutter/material.dart';

import '../../theme.dart';

/// Goldmünze mit kleinem Gesicht und Glitzer.
class KawaiiCoin extends StatelessWidget {
  const KawaiiCoin({super.key});

  @override
  Widget build(BuildContext context) =>
      const AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _CoinPainter()));
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.4;

    canvas.drawCircle(c + Offset(0, s * 0.04), r, Paint()..color = AppColors.coinDeep);
    canvas.drawCircle(c, r, Paint()..color = AppColors.coin);
    canvas.drawCircle(
      c,
      r * 0.75,
      Paint()
        ..color = AppColors.coinDeep.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03,
    );

    // Gesicht
    final ink = Paint()..color = AppColors.ink;
    canvas.drawCircle(c + Offset(-s * 0.1, -s * 0.03), s * 0.035, ink);
    canvas.drawCircle(c + Offset(s * 0.1, -s * 0.03), s * 0.035, ink);
    final smile = Path()
      ..moveTo(c.dx - s * 0.05, c.dy + s * 0.05)
      ..quadraticBezierTo(c.dx, c.dy + s * 0.11, c.dx + s * 0.05, c.dy + s * 0.05);
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round,
    );
    final blush = Paint()..color = AppColors.pink.withValues(alpha: 0.8);
    canvas.drawCircle(c + Offset(-s * 0.18, s * 0.05), s * 0.04, blush);
    canvas.drawCircle(c + Offset(s * 0.18, s * 0.05), s * 0.04, blush);

    // Glitzer
    _sparkle(canvas, c + Offset(r * 0.85, -r * 0.85), s * 0.1);
  }

  static void _sparkle(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => false;
}
