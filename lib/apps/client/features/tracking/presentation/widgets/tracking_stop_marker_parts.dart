import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/markers/pulse_halo.dart';

/// One stop, as a circle. Every stop on the live map is this shape — only the
/// size, the fill and the ring change with its state, which is what lets the
/// rider read the whole route without a legend.
class TrackingStopDot extends StatelessWidget {
  const TrackingStopDot({
    super.key,
    required this.diameter,
    required this.fill,
    this.ring,
    this.ringWidth = 2,
    this.icon,
  });

  final double diameter;
  final Color fill;
  final Color? ring;
  final double ringWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: ring ?? Colors.white,
          width: ring == null ? 2 : ringWidth,
        ),
        boxShadow: MapStyle.shadow(context),
      ),
      child: icon == null
          ? null
          : Icon(icon, size: diameter * 0.55, color: Colors.white),
    );
  }
}

/// Wraps a dot in the shared breathing halo used for "the bus is here" and
/// "the bus is heading here".
class TrackingStopPulse extends StatelessWidget {
  const TrackingStopPulse({
    super.key,
    required this.color,
    required this.diameter,
    required this.child,
  });

  final Color color;
  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      
      clipBehavior: Clip.none,
      children: [
        MapPulseHalo(color: color, diameter: diameter),
        child,
      ],
    );
  }
}

/// The stop's name, on the two stops worth naming.
class TrackingStopLabel extends StatelessWidget {
  const TrackingStopLabel({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(235),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: color,
        ),
      ),
    );
  }
}
