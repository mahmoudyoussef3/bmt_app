import 'package:flutter/material.dart';

/// The EasyWay pin tail: a smooth curved drop (not a sharp triangle), so the
/// marker reads as a rounded badge flowing to a point rather than a classic
/// map-pin teardrop — part of what makes a screenshot read as EasyWay rather
/// than a generic map SDK pin.
class PinTailPainter extends CustomPainter {
  const PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.55, size.width / 2, size.height)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.55, size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PinTailPainter old) => old.color != color;
}
