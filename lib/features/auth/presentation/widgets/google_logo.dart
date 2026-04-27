import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2;
    final double radius = s / 2;
    final double strokeWidth = s * 0.18;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final double arcRadius = radius - strokeWidth / 2;

    // Blue arc (right side, -45° to 45° roughly = bottom-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: arcRadius),
      -math.pi / 4, // -45°
      math.pi / 2,  // 90° sweep
      false,
      paint,
    );

    // Green arc (bottom, 45° to 135°)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: arcRadius),
      math.pi / 4, // 45°
      math.pi / 2, // 90° sweep
      false,
      paint,
    );

    // Yellow arc (left-bottom, 135° to 225°)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: arcRadius),
      3 * math.pi / 4, // 135°
      math.pi / 2,     // 90° sweep
      false,
      paint,
    );

    // Red arc (top, 225° to 315° = -45°)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: arcRadius),
      5 * math.pi / 4, // 225°
      math.pi / 2,     // 90° sweep
      false,
      paint,
    );

    // Horizontal bar (the "crossbar" of the G) - blue
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barHeight = strokeWidth;
    final double barLeft = center;
    final double barTop = center - barHeight / 2;
    final double barRight = s - strokeWidth * 0.3;

    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barTop + barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
