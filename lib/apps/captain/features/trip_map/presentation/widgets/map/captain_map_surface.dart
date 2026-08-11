import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import 'captain_map_layers.dart';
import 'captain_map_vehicle.dart';

class CaptainMapSurface extends StatelessWidget {
  const CaptainMapSurface({
    super.key,
    required this.controller,
    required this.center,
    required this.zoom,
    required this.initialFit,
    required this.route,
    required this.progress,
    required this.vehicle,
    required this.activePickup,
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
  final CaptainMapVehicle vehicle;
  final LatLng? activePickup;
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
            flags:
                InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: buildCaptainMapLayers(
          context: context,
          route: route,
          progress: progress,
          vehicle: vehicle,
          activePickup: activePickup,
          zoom: zoom,
        ),
      ),
    );
  }
}
