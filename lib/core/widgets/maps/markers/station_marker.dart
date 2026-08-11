import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/markers/pin_tail_painter.dart';
import 'package:bmt_app/core/widgets/maps/markers/pulse_halo.dart';

/// Builds a tappable station pin whose pointer tip sits exactly on the
/// coordinate. Start / destination pins are prominent; intermediate stops are
/// compact numbered dots. Pins scale-fade in (lightly staggered along the
/// route) and the selected pin elevates with a soft pulse.
Marker buildStationMarker(
  BuildContext context, {
  required MapRouteStop stop,
  required int index,
  required int count,
  required VoidCallback onTap,
  bool selected = false,
}) {
  final prominent = index == 0 || index == count - 1;
  final color = MapStyle.colorFor(context, index, count);
  final label = MapStyle.labelFor(index, count);
  final box = MapStyle.pinBox(prominent);

  return Marker(
    point: stop.coordinate,
    width: box.width,
    height: box.height,
    
    alignment: MapStyle.pinAnchor,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Route stop ${MapStyle.roleFor(index, count)}',
        child: _MarkerEntrance(
          staggerIndex: index,
          child: _StationPin(
            color: color,
            label: label,
            prominent: prominent,
            selected: selected,
          ),
        ),
      ),
    ),
  );
}

/// One-shot scale + fade entrance, staggered a touch per stop so the route
/// "populates" instead of popping in. State survives rebuilds, so toggling a
/// callout never replays the entrance.
class _MarkerEntrance extends StatelessWidget {
  const _MarkerEntrance({required this.staggerIndex, required this.child});

  final int staggerIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion) {
      return child;
    }
    final delayMs = 60 * staggerIndex.clamp(0, 6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + delayMs),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.scale(
            scale: 0.55 + 0.45 * value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
    );
  }
}

/// The EasyWay station pin: a rounded-square ("squircle") badge flowing into
/// a curved tail — distinct from the circular teardrop pins of every
/// mainstream map SDK, while keeping the same entrance/pulse/shadow language.
class _StationPin extends StatelessWidget {
  const _StationPin({
    required this.color,
    required this.label,
    required this.prominent,
    required this.selected,
  });

  final Color color;
  final String label;
  final bool prominent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final diameter = prominent ? 40.0 : 30.0;
    final shadows = selected
        ? [
            BoxShadow(
              color: color.withAlpha(90),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
        : MapStyle.shadow(context);

    return AnimatedScale(
      scale: selected ? 1.14 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (selected) MapPulseHalo(color: color, diameter: diameter),
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                  ),
                  borderRadius: BorderRadius.circular(diameter * 0.34),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: shadows,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: prominent ? 15 : 12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          CustomPaint(
            size: Size(prominent ? 14 : 11, prominent ? 9 : 7),
            painter: PinTailPainter(color),
          ),
        ],
      ),
    );
  }
}
