import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/route_path_math.dart';
import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';


class SimpleVehicleData {
  const SimpleVehicleData({
    required this.position,
    this.headingDegrees = 0,
    this.accuracyMeters,
  });

  final LatLng position;

  /// Compass heading of travel (0 = north, clockwise).
  final double headingDegrees;

  /// GPS accuracy radius; the layer draws a soft circle when provided.
  final double? accuracyMeters;
}


class SimpleVehicleLayer extends StatefulWidget {
  const SimpleVehicleLayer({super.key, required this.vehicle});

  final SimpleVehicleData? vehicle;

  @override
  State<SimpleVehicleLayer> createState() => _SimpleVehicleLayerState();
}

class _SimpleVehicleLayerState extends State<SimpleVehicleLayer>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  SimpleVehicleData? _from;
  SimpleVehicleData? _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1,
    );
    _from = _to = widget.vehicle;
  }

  @override
  void didUpdateWidget(SimpleVehicleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.vehicle;
    if (next == null || _to == null) {
      // First fix (or tracking stopped): snap, don't animate from nowhere.
      _from = _to = next;
      _controller.value = 1;
      return;
    }
    if (identical(next, _to)) return;
    _from = _current();
    _to = next;
    if (AppMotion.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  /// The interpolated pose at this instant, so retargeting mid-flight never
  /// causes a jump backwards.
  SimpleVehicleData _current() {
    final from = _from, to = _to;
    if (from == null || to == null) return to ?? from!;
    if (AppMotion.reduceMotion) {
      return to;
    }
    final t = Curves.easeInOut.transform(_controller.value);
    return SimpleVehicleData(
      position: RoutePathMath.lerpPosition(from.position, to.position, t),
      headingDegrees: RoutePathMath.lerpHeading(
        from.headingDegrees,
        to.headingDegrees,
        t,
      ),
      accuracyMeters: to.accuracyMeters,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_to == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pose = _current();
        final accuracy = pose.accuracyMeters ?? 0;
        final color = MapStyle.routeLine(context);
        return Stack(
          children: [
            if (accuracy > 0)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: pose.position,
                    radius: accuracy,
                    useRadiusInMeter: true,
                    color: color.withAlpha(22),
                    borderColor: color.withAlpha(60),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pose.position,
                  width: 44,
                  height: 44,
                  child: _VehicleMarker(
                    headingDegrees: pose.headingDegrees,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.headingDegrees, required this.color});

  final double headingDegrees;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDegrees * math.pi / 180,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, Color.lerp(color, Colors.black, 0.22)!],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: MapStyle.shadow(context),
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
