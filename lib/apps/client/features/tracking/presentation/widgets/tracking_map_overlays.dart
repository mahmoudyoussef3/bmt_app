import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/markers/pulse_halo.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';

/// Builds the live map's stop markers: per-stop visit-state badges once
/// progress data exists, otherwise plain start/end station pins from the
/// shared kit.
List<Marker> buildTrackingStopMarkers(
  BuildContext context, {
  required List<LatLng> route,
  required List<StopProgress> stops,
}) {
  if (stops.isEmpty) {
    final fallback = [
      if (route.isNotEmpty) MapRouteStop(coordinate: route.first),
      if (route.length > 1) MapRouteStop(coordinate: route.last),
    ];
    return [
      for (final entry in fallback.indexed)
        buildStationMarker(
          context,
          stop: entry.$2,
          index: entry.$1,
          count: fallback.length,
          onTap: () {},
        ),
    ];
  }
  return [
    for (final (i, stop) in stops.indexed)
      if (stop.stop.hasCoordinates)
        Marker(
          point: LatLng(stop.stop.latitude, stop.stop.longitude),
          width: 44,
          height: 44,
          child: TrackingProgressStopMarker(
            status: stop.status,
            isDestination: i == stops.length - 1,
          ),
        ),
  ];
}

/// Stop marker whose look follows the route progress engine's visit state:
/// visited stops turn green with a check, the stop the bus is at pulses,
/// the next stop shows a bold ring, and future stops stay muted dots. Built
/// from the shared map kit's halo/shadow/color primitives so it reads as
/// part of the same EasyWay map language as the station pins used elsewhere.
class TrackingProgressStopMarker extends StatelessWidget {
  const TrackingProgressStopMarker({
    super.key,
    required this.status,
    this.isDestination = false,
  });

  final StopVisitStatus status;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final routeColor = MapStyle.routeLine(context);
    return switch (status) {
      StopVisitStatus.departed => _core(
        context,
        size: 22,
        color: ClientColors.journeyGreen,
        child: const Icon(Icons.check, size: 13, color: Colors.white),
      ),
      StopVisitStatus.arrived => Stack(
        alignment: Alignment.center,
        children: [
          MapPulseHalo(color: routeColor, diameter: 26),
          _core(
            context,
            size: 26,
            color: routeColor,
            child: const Icon(
              Icons.directions_bus_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
      StopVisitStatus.next => Stack(
        alignment: Alignment.center,
        children: [
          MapPulseHalo(color: routeColor, diameter: 22),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: routeColor, width: 3.5),
            ),
          ),
        ],
      ),
      StopVisitStatus.upcoming => isDestination
          ? _core(
              context,
              size: 26,
              color: Colors.white,
              border: MapStyle.end(context),
              child: Icon(
                Icons.location_on_rounded,
                size: 16,
                color: MapStyle.end(context),
              ),
            )
          : Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: routeColor.withAlpha(190), width: 3),
                boxShadow: MapStyle.shadow(context),
              ),
            ),
    };
  }

  Widget _core(
    BuildContext context, {
    required double size,
    required Color color,
    required Widget child,
    Color? border,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: border == null ? null : Border.all(color: border, width: 2.5),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Center(child: child),
    );
  }
}
