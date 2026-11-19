import 'dart:math';

import 'package:flutter/material.dart';

import '../../../exercises/outfits.dart';
import '../../theme.dart';

enum RobotMood { normal, happy, dizzy }

/// Der niedliche Roboter – komplett mit Code gezeichnet, keine Bilddateien nötig.
class KawaiiRobot extends StatelessWidget {
  const KawaiiRobot({super.key, this.mood = RobotMood.normal, this.size, this.outfit = Outfit.none});

  final RobotMood mood;
  final Outfit outfit;

  /// `null` = verfügbaren Platz füllen.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(painter: _RobotPainter(mood, outfit));
    return size == null
        ? AspectRatio(aspectRatio: 1, child: painter)
        : SizedBox.square(dimension: size, child: painter);
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter(this.mood, this.outfit);

  final RobotMood mood;
  final Outfit outfit;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Antenne mit Herz
    canvas.drawLine(p(0.5, 0.24), p(0.5, 0.12), outline);
    _heart(canvas, p(0.5, 0.09), s * 0.075, mood == RobotMood.dizzy ? AppColors.lavender : AppColors.pinkDeep);

    // Öhrchen
    final ear = Paint()..color = AppColors.pink;
    for (final x in [0.11, 0.89]) {
      canvas.drawCircle(p(x, 0.56), s * 0.065, ear);
      canvas.drawCircle(p(x, 0.56), s * 0.065, outline);
    }

    // Kopf/Körper
    final body = RRect.fromRectAndRadius(Rect.fromPoints(p(0.14, 0.24), p(0.86, 0.9)), Radius.circular(s * 0.24));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2FFFA), AppColors.mint],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(body, outline);

    // Display-Gesicht
    final screen = RRect.fromRectAndRadius(Rect.fromPoints(p(0.24, 0.35), p(0.76, 0.76)), Radius.circular(s * 0.15));
    canvas.drawRRect(screen, Paint()..color = AppColors.ink);

    // Bäckchen
    final blush = Paint()..color = AppColors.pink.withValues(alpha: mood == RobotMood.dizzy ? 0.9 : 0.75);
    for (final x in [0.32, 0.68]) {
      canvas.drawOval(Rect.fromCenter(center: p(x, 0.65), width: s * 0.1, height: s * 0.055), blush);
    }

    _eyes(canvas, s, p);
    _mouth(canvas, s, p);
    _outfit(canvas, s, p, outline);
  }

  void _outfit(Canvas canvas, double s, Offset Function(double, double) p, Paint outline) {
    Paint fill(Color c) => Paint()..color = c;
    final thin = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeJoin = StrokeJoin.round;
    switch (outfit) {
      case Outfit.none:
        return;
      case Outfit.bow:
        final left = Path()..moveTo(0.74 * s, 0.27 * s)..lineTo(0.62 * s, 0.19 * s)..lineTo(0.63 * s, 0.35 * s)..close();
        final right = Path()..moveTo(0.74 * s, 0.27 * s)..lineTo(0.86 * s, 0.19 * s)..lineTo(0.85 * s, 0.35 * s)..close();
        for (final b in [left, right]) {
          canvas.drawPath(b, fill(AppColors.pinkDeep));
          canvas.drawPath(b, thin);
        }
        canvas.drawCircle(p(0.74, 0.27), s * 0.035, fill(AppColors.pink));
        canvas.drawCircle(p(0.74, 0.27), s * 0.035, thin);
      case Outfit.flower:
        const colors = [AppColors.pink, AppColors.butter, AppColors.lavender, AppColors.pink, AppColors.butter];
        for (var i = 0; i < 5; i++) {
          final c = p(0.26 + i * 0.12, 0.25 - (i == 2 ? 0.02 : (i == 1 || i == 3 ? 0.01 : 0)));
          for (var k = 0; k < 5; k++) {
            final a = k * 2 * pi / 5;
            canvas.drawCircle(c + Offset(cos(a), sin(a)) * s * 0.03, s * 0.026, fill(colors[i]));
          }
          canvas.drawCircle(c, s * 0.022, fill(Colors.white));
        }
      case Outfit.headphones:
        final band = Paint()
          ..color = AppColors.lavenderDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: p(0.5, 0.5), width: s * 0.84, height: s * 0.76), pi * 1.05, pi * 0.9, false, band);
        for (final x in [0.1, 0.9]) {
          final cup = RRect.fromRectAndRadius(Rect.fromCenter(center: p(x, 0.56), width: s * 0.14, height: s * 0.22), Radius.circular(s * 0.06));
          canvas.drawRRect(cup, fill(AppColors.lavender));
          canvas.drawRRect(cup, thin);
        }
      case Outfit.catEars:
        for (final dir in [-1.0, 1.0]) {
          Offset q(double x, double y) => p(0.5 + dir * x, y);
          final ear = Path()..moveTo(q(0.14, 0.29).dx, q(0.14, 0.29).dy)..lineTo(q(0.3, 0.07).dx, q(0.3, 0.07).dy)..lineTo(q(0.36, 0.33).dx, q(0.36, 0.33).dy)..close();
          final inner = Path()..moveTo(q(0.2, 0.28).dx, q(0.2, 0.28).dy)..lineTo(q(0.29, 0.14).dx, q(0.29, 0.14).dy)..lineTo(q(0.32, 0.3).dx, q(0.32, 0.3).dy)..close();
          canvas.drawPath(ear, fill(AppColors.lavender));
          canvas.drawPath(ear, thin);
          canvas.drawPath(inner, fill(AppColors.pink));
        }
      case Outfit.wizardHat:
        final hat = Path()..moveTo(0.28 * s, 0.28 * s)..quadraticBezierTo(0.5 * s, 0.1 * s, 0.6 * s, -0.04 * s)..lineTo(0.72 * s, 0.28 * s)..close();
        canvas.drawPath(hat, fill(AppColors.lavenderDeep));
        canvas.drawPath(hat, thin);
        final brim = Rect.fromCenter(center: p(0.5, 0.28), width: s * 0.62, height: s * 0.1);
        canvas.drawOval(brim, fill(AppColors.lavenderDeep));
        canvas.drawOval(brim, thin);
        _star(canvas, p(0.52, 0.16), s * 0.05, fill(AppColors.butter));
      case Outfit.crown:
        final crown = Path()
          ..moveTo(0.3 * s, 0.29 * s)
          ..lineTo(0.28 * s, 0.13 * s)
          ..lineTo(0.39 * s, 0.21 * s)
          ..lineTo(0.5 * s, 0.08 * s)
          ..lineTo(0.61 * s, 0.21 * s)
          ..lineTo(0.72 * s, 0.13 * s)
          ..lineTo(0.7 * s, 0.29 * s)
          ..close();
        canvas.drawPath(crown, fill(AppColors.coin));
        canvas.drawPath(crown, thin);
        canvas.drawCircle(p(0.5, 0.235), s * 0.03, fill(AppColors.pinkDeep));
    }
  }

  static void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final pt = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  void _eyes(Canvas canvas, double s, Offset Function(double, double) p) {
    final glow = Paint()..color = const Color(0xFFBFFFEA);
    final line = Paint()
      ..color = const Color(0xFFBFFFEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    for (final x in [0.38, 0.62]) {
      final c = p(x, 0.52);
      switch (mood) {
        case RobotMood.normal:
          canvas.drawOval(Rect.fromCenter(center: c, width: s * 0.09, height: s * 0.12), glow);
          canvas.drawCircle(c + Offset(s * 0.015, -s * 0.025), s * 0.018, Paint()..color = Colors.white);
        case RobotMood.happy:
          // ^ ^
          final path = Path()
            ..moveTo(c.dx - s * 0.045, c.dy + s * 0.02)
            ..quadraticBezierTo(c.dx, c.dy - s * 0.06, c.dx + s * 0.045, c.dy + s * 0.02);
          canvas.drawPath(path, line);
        case RobotMood.dizzy:
          // × ×
          final d = s * 0.035;
          canvas.drawLine(c + Offset(-d, -d), c + Offset(d, d), line);
          canvas.drawLine(c + Offset(d, -d), c + Offset(-d, d), line);
      }
    }
  }

  void _mouth(Canvas canvas, double s, Offset Function(double, double) p) {
    final mouth = Paint()
      ..color = AppColors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;
    final c = p(0.5, 0.66);
    switch (mood) {
      case RobotMood.normal:
        // kleines "w"
        final w = Path()
          ..moveTo(c.dx - s * 0.05, c.dy - s * 0.01)
          ..quadraticBezierTo(c.dx - s * 0.025, c.dy + s * 0.035, c.dx, c.dy - s * 0.005)
          ..quadraticBezierTo(c.dx + s * 0.025, c.dy + s * 0.035, c.dx + s * 0.05, c.dy - s * 0.01);
        canvas.drawPath(w, mouth);
      case RobotMood.happy:
        final open = Path()
          ..moveTo(c.dx - s * 0.05, c.dy - s * 0.015)
          ..quadraticBezierTo(c.dx, c.dy + s * 0.07, c.dx + s * 0.05, c.dy - s * 0.015)
          ..close();
        canvas.drawPath(open, Paint()..color = AppColors.pink);
      case RobotMood.dizzy:
        final wave = Path()..moveTo(c.dx - s * 0.06, c.dy);
        for (var i = 0; i < 4; i++) {
          final x = c.dx - s * 0.06 + (i + 1) * s * 0.03;
          wave.quadraticBezierTo(x - s * 0.015, c.dy + (i.isEven ? -1 : 1) * s * 0.025, x, c.dy);
        }
        canvas.drawPath(wave, mouth);
    }
  }

  static void _heart(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + r * 0.9)
      ..cubicTo(center.dx - r * 1.6, center.dy - r * 0.2, center.dx - r * 0.6, center.dy - r * 1.3, center.dx, center.dy - r * 0.4)
      ..cubicTo(center.dx + r * 0.6, center.dy - r * 1.3, center.dx + r * 1.6, center.dy - r * 0.2, center.dx, center.dy + r * 0.9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) => oldDelegate.mood != mood || oldDelegate.outfit != outfit;
}

/// Kleines Herz – auch für Flagge und Dekoration.
class KawaiiHeart extends StatelessWidget {
  const KawaiiHeart({super.key, required this.size, this.color = AppColors.pinkDeep});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _HeartPainter(color));
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      _RobotPainter._heart(canvas, size.center(Offset.zero), min(size.width, size.height) * 0.45, color);

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) => oldDelegate.color != color;
}
