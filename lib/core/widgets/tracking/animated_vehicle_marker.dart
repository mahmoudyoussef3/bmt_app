import 'dart:math' as math;

import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:flutter/material.dart';

import '../../tracking/vehicle_sample.dart';
import 'bus_silhouette.dart';
import 'heading_wedge.dart';

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
    final reducedMotion = AppMotion.reduceMotion;
    final haloAlpha = sample.isStale
        ? 30
        : reducedMotion || pulseValue == null
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
                child: HeadingWedge(color: tone),
              ),
            ),
          ),
        Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tone, Color.lerp(tone, Colors.black, 0.2)!],
            ),
            borderRadius: BorderRadius.circular(size * 0.6 * 0.34),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.6 * 0.24),
          child: sample.isMoving || sample.isStale
              ? const BusSilhouette()
              : Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: size * 0.26,
                ),
        ),
      ],
    );
  }
}

