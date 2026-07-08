import 'package:flutter/material.dart';

/// The small triangular wedge that orbits [AnimatedVehicleMarker] pointing in
/// the direction of travel.
class HeadingWedge extends StatelessWidget {
  const HeadingWedge({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(14, 10), painter: _WedgePainter(color));
  }
}

class _WedgePainter extends CustomPainter {
  const _WedgePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.72)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_WedgePainter oldDelegate) => oldDelegate.color != color;
}
