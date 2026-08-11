import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/core/maps/route_path_math.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/route_line_style.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';
import 'package:bmt_app/core/widgets/tracking/live_vehicle_layer.dart';

import 'captain_map_stop_markers.dart';
import 'captain_map_vehicle.dart';

List<Widget> buildCaptainMapLayers({
  required BuildContext context,
  required List<LatLng> route,
  required RouteProgressSnapshot? progress,
  required CaptainMapVehicle vehicle,
  required LatLng? activePickup,
  required double zoom,
}) {
  final (traveled, remaining) = _split(route, progress);

  return [
    const EasyWayTileLayer(),
    if (route.length > 1)
      PolylineLayer(
        polylines: [
          ...buildRoutePolylines(
            context,
            traveled,
            color: CaptainColors.offline,
            glow: false,
            style: RouteLineStyle.trail,
          ),
          ...buildRoutePolylines(
            context,
            remaining,
            style: RouteLineStyle.navigation,
          ),
        ],
      ),
    MarkerLayer(
      markers: buildCaptainStopMarkers(
        route: route,
        stops: progress?.stops ?? const <StopProgress>[],
        activePickup: activePickup,
        zoom: zoom,
      ),
    ),
    AnimatedBuilder(
      animation: vehicle.pulse,
      builder: (context, _) => LiveVehicleLayer(
        controller: vehicle.track,
        color: CaptainColors.primary,
        pulseValue: vehicle.pulse.value,
      ),
    ),
  ];
}

(List<LatLng>, List<LatLng>) _split(
  List<LatLng> route,
  RouteProgressSnapshot? progress,
) {
  final fraction = progress?.routeFraction ?? 0;
  if (route.length < 2 || fraction <= 0) return (const [], route);
  final cumulative = RoutePathMath.cumulativeDistances(route);
  return RoutePathMath.splitAtFraction(route, cumulative, fraction);
}
