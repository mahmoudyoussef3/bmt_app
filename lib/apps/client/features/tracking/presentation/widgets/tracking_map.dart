import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_empty_panel.dart';

import '../../domain/entities/tracking_trip.dart';
import '../formatters/tracking_labels.dart';
import 'map/tracking_map_camera.dart';
import 'map/tracking_map_road.dart';
import 'map/tracking_map_surface.dart';
import 'map/tracking_map_vehicle.dart';
import 'tracking_map_chrome.dart';

/// The live map: the shared EasyWay basemap, the route on real road geometry,
/// the ordered stop markers, and the captain's interpolated vehicle.
///
/// It carries no cards and no prose of its own — only the route, the stops, the
/// vehicle and the controls. Everything a rider needs to *read* lives in the
/// sheet below, where it is not sitting on top of the road they are following.
class TrackingMap extends StatefulWidget {
  const TrackingMap({
    super.key,
    required this.routePoints,
    required this.vehicleFix,
    required this.progress,
    required this.labels,
    required this.onRetry,
    this.sheetController,
    this.borderRadius = 0,
  });

  final List<TrackingPoint> routePoints;
  final TrackingPoint? vehicleFix;
  final RouteProgressSnapshot? progress;
  final TrackingLabels labels;
  final VoidCallback onRetry;

  /// The sheet covering part of the map; its extent pads the camera fit.
  final DraggableScrollableController? sheetController;
  final double borderRadius;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TrackingMapRoad _road = TrackingMapRoad();
  late final TrackingMapCamera _camera;
  late final TrackingMapVehicle _vehicleLayer;
  double _zoom = 13;

  @override
  void initState() {
    super.initState();
    _camera = TrackingMapCamera(vsync: this, controller: _mapController);
    _vehicleLayer = TrackingMapVehicle(vsync: this)..addListener(_follow);
    _road.addListener(_onRoadLoaded);
    _vehicleLayer.feed(widget.vehicleFix);
    _road.sync(widget.routePoints);
  }

  @override
  void didUpdateWidget(TrackingMap old) {
    super.didUpdateWidget(old);
    _vehicleLayer.feed(widget.vehicleFix);
    final before = _road.signature;
    _road.sync(widget.routePoints);
    if (_camera.isReady && before != _road.signature) _fit();
  }

  @override
  void dispose() {
    _vehicleLayer
      ..removeListener(_follow)
      ..dispose();
    _road.removeListener(_onRoadLoaded);
    _road.dispose();
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onRoadLoaded() {
    if (!mounted) return;
    setState(() {});
    if (_camera.isReady) _fit();
  }

  LatLng? get _vehicle {
    final fix = widget.vehicleFix;
    return fix == null ? null : LatLng(fix.latitude, fix.longitude);
  }

  double get _sheetInset {
    final controller = widget.sheetController;
    if (controller == null || !controller.isAttached) return 0;
    return controller.size * MediaQuery.sizeOf(context).height;
  }

  void _follow() {
    final sample = _vehicleLayer.sample;
    if (sample == null) return;
    _camera.followTo(LatLng(sample.latitude, sample.longitude));
  }

  void _fit() => _camera.fit(_road.points, _vehicle, _sheetInset);

  @override
  Widget build(BuildContext context) {
    final route = _road.points;
    final center = _vehicle ?? (route.isNotEmpty ? route.first : null);

    if (center == null) {
      return MapEmptyPanel(
        title: widget.labels.l10n.tracking_mapUnavailableTitle,
        message: widget.labels.l10n.tracking_mapUnavailableBody,
        onRetry: widget.onRetry,
      );
    }

    final map = Stack(
      children: [
        TrackingMapSurface(
          controller: _mapController,
          center: center,
          zoom: _zoom,
          initialFit: _camera.fitFor(route, _vehicle, _sheetInset),
          route: route,
          progress: widget.progress,
          vehicle: _vehicleLayer,
          onMapReady: _camera.markReady,
          onMapEvent: _onMapEvent,
          onPositionChanged: _onPositionChanged,
        ),
        TrackingMapChrome(
          sheetController: widget.sheetController,
          onRecenter: _fit,
          onZoomIn: () => _camera.zoomBy(1),
          onZoomOut: () => _camera.zoomBy(-1),
          onToggleFollow: () {
            setState(_camera.resumeFollow);
            _follow();
          },
          followActive: _camera.isFollowing,
          showRouting: _road.hasRoad,
        ),
      ],
    );

    if (widget.borderRadius == 0) return map;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: map,
    );
  }

  /// Stop markers thin out and gain labels by zoom, so the camera feeds its
  /// zoom back into the build — but only on a step big enough to change what is
  /// drawn, or every pinch frame rebuilds the marker layer.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if ((camera.zoom - _zoom).abs() < 0.25) return;
    setState(() => _zoom = camera.zoom);
  }

  void _onMapEvent(MapEvent event) {
    if (_camera.breaksFollow(event)) setState(_camera.stopFollowing);
  }
}
