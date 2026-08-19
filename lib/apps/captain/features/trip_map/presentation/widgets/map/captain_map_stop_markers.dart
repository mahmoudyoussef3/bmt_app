import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/markers/pulse_halo.dart';

List<Marker> buildCaptainStopMarkers({
  required List<LatLng> route,
  required List<StopProgress> stops,
  required LatLng? activePickup,
  required double zoom,
}) {
  final markers = <Marker>[];
  final labelled = zoom >= 13;

  for (var i = 0; i < route.length; i++) {
    final point = route[i];
    final status = i < stops.length
        ? stops[i].status
        : StopVisitStatus.upcoming;
    final isDestination = i == route.length - 1;
    final isActivePickup =
        activePickup != null && _sameSpot(point, activePickup);
    final name = i < stops.length ? stops[i].stop.name : null;

    markers.add(
      Marker(
        point: point,
        width: 120,
        height: isActivePickup ? 78 : 56,
        child: isActivePickup
            ? _PickupPin(name: labelled ? name : null)
            : _StopMarker(
                status: status,
                isDestination: isDestination,
                name:
                    (labelled &&
                        (isDestination || status == StopVisitStatus.next))
                    ? name
                    : null,
              ),
      ),
    );
  }
  return markers;
}

bool _sameSpot(LatLng a, LatLng b) =>
    (a.latitude - b.latitude).abs() < 1e-6 &&
    (a.longitude - b.longitude).abs() < 1e-6;

class _PickupPin extends StatelessWidget {
  const _PickupPin({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const MapPulseHalo(color: CaptainColors.primary, diameter: 34),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: CaptainColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: MapStyle.shadow(context),
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (name != null)
          Positioned(
            bottom: -18,
            child: _MarkerLabel(text: name!, color: CaptainColors.primary),
          ),
      ],
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({
    required this.status,
    required this.isDestination,
    this.name,
  });

  final StopVisitStatus status;
  final bool isDestination;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name;
    if (label == null) return Center(child: _dot(context));
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _dot(context),
        Positioned(
          bottom: -16,
          child: _MarkerLabel(
            text: label,
            color: isDestination ? CaptainColors.error : CaptainColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context) {
    if (isDestination && status != StopVisitStatus.departed) {
      return _Dot(
        diameter: 22,
        fill: CaptainColors.error,
        icon: Icons.flag_rounded,
      );
    }
    return switch (status) {
      StopVisitStatus.departed => const _Dot(
        diameter: 11,
        fill: CaptainColors.offline,
      ),
      StopVisitStatus.arrived => _Dot(
        diameter: 22,
        fill: CaptainColors.primary,
        icon: Icons.directions_bus_rounded,
      ),
      StopVisitStatus.next => _Dot(
        diameter: 16,
        fill: Colors.white,
        ring: CaptainColors.primary,
        ringWidth: 4,
      ),
      StopVisitStatus.upcoming => _Dot(
        diameter: 11,
        fill: Colors.white,
        ring: CaptainColors.primary.withAlpha(150),
        ringWidth: 3,
      ),
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
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

class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(235),
        borderRadius: BorderRadius.circular(999),
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
