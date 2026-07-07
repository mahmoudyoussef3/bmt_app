import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tracking/vehicle_sample.dart';

/// The vehicle map marker: a circular bus badge with a heading wedge that
/// orbits the badge pointing in the direction of travel, an optional soft
/// pulse halo while live, and greyed-out styling once the fix goes stale.
class AnimatedVehicleMarker extends StatelessWidget {
  const AnimatedVehicleMarker({
    super.key,
    required this.sample,
    required this.color,
    this.staleColor = const Color(0xFF9E9E9E),
    this.pulseValue,
    this.size = 58,
  });

  final VehicleSample sample;
  final Color color;
  final Color staleColor;

  /// 0..1 external pulse phase; omit for a static halo.
  final double? pulseValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = sample.isStale ? staleColor : color;
    final haloAlpha = sample.isStale
        ? 30
        : pulseValue == null
        ? 55
        : (55 + 90 * math.sin(pulseValue! * math.pi)).round().clamp(0, 255);
    final showHeading = !sample.isStale && sample.isMoving;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone.withAlpha(haloAlpha),
          ),
        ),
        if (showHeading)
          Transform.rotate(
            angle: sample.headingDegrees * math.pi / 180,
            child: SizedBox(
              width: size,
              height: size,
              child: Align(
                alignment: Alignment.topCenter,
                child: _HeadingWedge(color: tone),
              ),
            ),
          ),
        Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            sample.isMoving || sample.isStale
                ? Icons.directions_bus_rounded
                : Icons.pause_circle_filled_rounded,
            size: size * 0.33,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HeadingWedge extends StatelessWidget {
  const _HeadingWedge({required this.color});

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
