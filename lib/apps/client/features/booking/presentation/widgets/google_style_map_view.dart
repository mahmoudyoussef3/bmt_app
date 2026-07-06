import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_layers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_markers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_overlays.dart';

/// A route map backed by a clean, theme-aware basemap.
///
/// The camera always fits the supplied route instead of relying on a fixed
/// city-level zoom. Invalid coordinates are ignored so the UI never renders a
/// plausible-looking marker for data that does not exist. Stops are tappable to
/// reveal their name, and zoom / recenter controls keep the route readable.
class GoogleStyleMapView extends StatefulWidget {
  const GoogleStyleMapView({
    super.key,
    this.pickup,
    this.destination,
    this.waypoints = const [],
    this.cameraPadding = const EdgeInsets.all(48),
    this.interactive = true,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final List<MapPinOption> waypoints;
  final EdgeInsets cameraPadding;
  final bool interactive;

  @override
  State<GoogleStyleMapView> createState() => _GoogleStyleMapViewState();
}

class _GoogleStyleMapViewState extends State<GoogleStyleMapView> {
  final MapController _mapController = MapController();
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final stops = _mapPoints();
    if (stops.isEmpty) return const RouteMapEmptyPanel();

    final coordinates = stops.map((stop) => stop.coordinate).toList();
    final cameraFit = coordinates.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(coordinates),
            padding: widget.cameraPadding,
            maxZoom: 15,
          )
        : null;
    final active = _activeIndex != null && _activeIndex! < stops.length
        ? stops[_activeIndex!]
        : null;

    return Stack(
      children: [
        FlutterMap(
          key: ValueKey(_coordinatesSignature(coordinates)),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerFor(coordinates),
            initialZoom: 14,
            initialCameraFit: cameraFit,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, _) => _dismissCallout(),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.flingAnimation
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            const RouteMapTileLayer(),
            if (coordinates.length > 1)
              RouteMapPolylineLayer(coordinates: coordinates),
            MarkerLayer(
              markers: [
                for (final entry in stops.indexed)
                  buildStationMarker(
                    context,
                    stop: entry.$2,
                    index: entry.$1,
                    count: stops.length,
                    onTap: () => _toggleCallout(entry.$1),
                  ),
              ],
            ),
            if (active != null)
              MarkerLayer(
                markers: [buildCalloutMarker(context, stop: active)],
              ),
          ],
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: RouteMapInfoPills(stopCount: stops.length),
        ),
        if (widget.interactive)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 12,
            child: Align(
              alignment: const Alignment(0, -0.15),
              child: RouteMapControls(
                onRecenter: () => _recenter(cameraFit, coordinates),
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
              ),
            ),
          ),
        const PositionedDirectional(
          end: 6,
          bottom: 6,
          child: RouteMapAttribution(),
        ),
      ],
    );
  }

  void _toggleCallout(int index) {
    setState(() => _activeIndex = _activeIndex == index ? null : index);
  }

  void _dismissCallout() {
    if (_activeIndex != null) setState(() => _activeIndex = null);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final target = (camera.zoom + delta).clamp(5.0, 18.0);
    _mapController.move(camera.center, target);
  }

  void _recenter(CameraFit? cameraFit, List<LatLng> coordinates) {
    _dismissCallout();
    if (cameraFit != null) {
      _mapController.fitCamera(cameraFit);
    } else if (coordinates.isNotEmpty) {
      _mapController.move(coordinates.first, 15);
    }
  }

  List<RouteMapStop> _mapPoints() {
    final pins = widget.waypoints.isNotEmpty
        ? widget.waypoints
        : <MapPinOption>[?widget.pickup, ?widget.destination];
    final points = <RouteMapStop>[];
    final seen = <String>{};

    for (final pin in pins) {
      final coordinate = _latLngFor(pin);
      if (coordinate == null) continue;
      final key =
          '${coordinate.latitude.toStringAsFixed(6)}:'
          '${coordinate.longitude.toStringAsFixed(6)}';
      if (!seen.add(key)) continue;
      points.add(RouteMapStop(coordinate: coordinate, name: pin.label.trim()));
    }
    return points;
  }

  LatLng? _latLngFor(MapPinOption pin) {
    final lat = pin.x;
    final lng = pin.y;
    if (!lat.isFinite ||
        !lng.isFinite ||
        (lat == 0 && lng == 0) ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng _centerFor(List<LatLng> points) {
    final lat = points.map((point) => point.latitude).reduce((a, b) => a + b);
    final lng = points.map((point) => point.longitude).reduce((a, b) => a + b);
    return LatLng(lat / points.length, lng / points.length);
  }

  String _coordinatesSignature(List<LatLng> coordinates) {
    return coordinates
        .map(
          (point) =>
              '${point.latitude.toStringAsFixed(5)},'
              '${point.longitude.toStringAsFixed(5)}',
        )
        .join('|');
  }
}
