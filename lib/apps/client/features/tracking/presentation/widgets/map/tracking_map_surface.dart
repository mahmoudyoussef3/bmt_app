import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import 'tracking_map_layers.dart';
import 'tracking_map_vehicle.dart';

/// The map surface itself: the tiles, the route, the stops and the vehicle.
///
/// Wrapped in a [RepaintBoundary] so a live fix repaints the map without
/// dragging the sheet's cards into the same frame.
class TrackingMapSurface extends StatelessWidget {
  const TrackingMapSurface({
    super.key,
    required this.controller,
    required this.center,
    required this.zoom,
    required this.initialFit,
    required this.route,
    required this.progress,
    required this.vehicle,
    required this.onMapReady,
    required this.onMapEvent,
    required this.onPositionChanged,
  });

  final MapController controller;
  final LatLng center;
  final double zoom;
  final CameraFit? initialFit;
  final List<LatLng> route;
  final RouteProgressSnapshot? progress;
  final TrackingMapVehicle vehicle;
  final VoidCallback onMapReady;
  final void Function(MapEvent) onMapEvent;
  final void Function(MapCamera, bool) onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          initialCameraFit: initialFit,
          onMapReady: onMapReady,
          onMapEvent: onMapEvent,
          onPositionChanged: onPositionChanged,
          
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: buildTrackingMapLayers(
          context: context,
          route: route,
          progress: progress,
          track: vehicle.track,
          pulse: vehicle.pulse,
          zoom: zoom,
        ),
      ),
    );
  }
}
