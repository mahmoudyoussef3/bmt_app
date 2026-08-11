import 'dart:math' as math;

import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:flutter/material.dart';

import '../../tracking/vehicle_sample.dart';
import 'bus_silhouette.dart';
import 'heading_cone.dart';

/// The live vehicle puck: a white-ringed circular bus badge, a direction cone
/// fanning out ahead of it while it moves, and a soft breathing halo while the
/// fix is fresh.
///
/// Round on purpose — stations are squircle pins, so shape alone tells the
/// rider which mark is the bus. The bus glyph stays put in every state (a
/// pause icon in its place made the vehicle stop looking like a vehicle);
/// motion is carried by the cone, and a lost signal by the grey tone.
class AnimatedVehicleMarker extends StatelessWidget {
  const AnimatedVehicleMarker({
    super.key,
    required this.sample,
    required this.color,
    this.staleColor = const Color(0xFF94A3B8),
    this.pulseValue,
    this.size = 48,
  });

  final VehicleSample sample;
  final Color color;
  final Color staleColor;

  /// 0..1 external pulse phase; omit for a static halo.
  final double? pulseValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final live = !sample.isStale;
    final tone = live ? color : staleColor;
    final haloAlpha = _haloAlpha(live, tone);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (haloAlpha > 0)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withAlpha(haloAlpha),
            ),

          ),
        if (live && sample.isMoving)
          HeadingCone(
            color: tone,
            size: size,
            headingDegrees: sample.headingDegrees,
          ),
        _VehicleBadge(tone: tone, diameter: size * 0.58),
      ],
    );
  }

  int _haloAlpha(bool live, Color tone) {
    if (!live) return 0;
    if (AppMotion.reduceMotion || pulseValue == null) return 40;
    return (26 + 34 * math.sin(pulseValue! * math.pi)).round().clamp(0, 255);
  }
}

class _VehicleBadge extends StatelessWidget {
  const _VehicleBadge({required this.tone, required this.diameter});

  final Color tone;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(46),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(diameter * 0.26),
      child: const BusSilhouette(),
    );
  }
}
