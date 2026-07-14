import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The direction cone behind the vehicle badge: solid where it meets the
/// vehicle, fading to nothing ahead of it — the same language as a phone
/// compass beam.
///
/// It replaces a detached arrow orbiting the badge, which read as a separate
/// object sitting on the map rather than as the vehicle's heading.
class HeadingCone extends StatelessWidget {
  const HeadingCone({
    super.key,
    required this.color,
    required this.size,
    required this.headingDegrees,
  });

  final Color color;
  final double size;

  /// Clockwise from north, matching `VehicleSample.headingDegrees`.
  final double headingDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDegrees * math.pi / 180,
      child: CustomPaint(
        size: Size.square(size),
        painter: _ConePainter(color),
      ),
    );
  }
}

class _ConePainter extends CustomPainter {
  const _ConePainter(this.color);

  final Color color;

  /// Wide enough to read as a direction at a glance, narrow enough not to
  /// smear over the stops on either side of the vehicle.
  static const _sweep = math.pi / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromCircle(center: center, radius: size.width / 2);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      // Canvas angles run from +x, so north is -pi/2; back off half the sweep
      // to center the cone on the heading.
      ..arcTo(bounds, -math.pi / 2 - _sweep / 2, _sweep, false)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha(140), color.withAlpha(0)],
          stops: const [0.2, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_ConePainter oldDelegate) => oldDelegate.color != color;
}
