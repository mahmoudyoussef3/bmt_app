import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/maps/route_path_math.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/route_line_style.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';
import 'package:bmt_app/core/widgets/tracking/live_vehicle_layer.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../tracking_map_overlays.dart';

/// The map's stack of layers: basemap, the route split into covered and
/// remaining, the ordered stop markers, and the vehicle.
List<Widget> buildTrackingMapLayers({
  required BuildContext context,
  required List<LatLng> route,
  required RouteProgressSnapshot? progress,
  required VehicleTrackController track,
  required Animation<double> pulse,
  required double zoom,
}) {
  final (traveled, remaining) = splitTrackingRoute(route, progress);

  return [
    const EasyWayTileLayer(),
    if (route.length > 1)
      PolylineLayer(
        polylines: [
          
          ...buildRoutePolylines(
            context,
            traveled,
            color: ClientColors.journeySlateFor(context),
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
      markers: buildTrackingStopMarkers(
        route: route,
        stops: progress?.stops ?? const <StopProgress>[],
        zoom: zoom,
      ),
    ),
    AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => LiveVehicleLayer(
        controller: track,
        color: ClientColors.primaryFor(context),
        pulseValue: pulse.value,
      ),
    ),
  ];
}

/// Splits the drawn path at the engine's route fraction, so the covered part
/// reads as done and the rest as ahead.
///
/// The fraction — not an absolute distance — is what is safe to reuse here: the
/// engine measures progress over the straight stop-to-stop line, which is
/// shorter than this road-following path.
(List<LatLng>, List<LatLng>) splitTrackingRoute(
  List<LatLng> route,
  RouteProgressSnapshot? progress,
) {
  final fraction = progress?.routeFraction ?? 0;
  if (route.length < 2 || fraction <= 0) return (const [], route);
  final cumulative = RoutePathMath.cumulativeDistances(route);
  return RoutePathMath.splitAtFraction(route, cumulative, fraction);
}
