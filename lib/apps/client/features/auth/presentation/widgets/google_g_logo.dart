import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A self-contained, network-free rendering of the Google "G" mark.
///
/// The original social buttons pointed [Image.network] at an SVG URL, which
/// Flutter cannot decode — so the buttons rendered a broken-image icon. This
/// paints the four-color glyph directly so it works offline and in tests.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.24;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Ring split into four colored arcs (0° = east, clockwise positive).
    canvas.drawArc(rect, _rad(-18), _rad(80), false, arc..color = _blue);
    canvas.drawArc(rect, _rad(60), _rad(72), false, arc..color = _green);
    canvas.drawArc(rect, _rad(130), _rad(72), false, arc..color = _yellow);
    canvas.drawArc(rect, _rad(200), _rad(92), false, arc..color = _red);

    // Signature blue crossbar reaching in from the right edge.
    final barPaint = Paint()..color = _blue;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - stroke / 2,
      radius + stroke / 2,
      stroke,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}
