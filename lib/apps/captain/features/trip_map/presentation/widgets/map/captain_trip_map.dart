import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_empty_panel.dart';

import '../../../domain/entities/captain_location_fix.dart';
import 'captain_map_camera.dart';
import 'captain_map_chrome.dart';
import 'captain_map_road.dart';
import 'captain_map_surface.dart';
import 'captain_map_vehicle.dart';

/// The captain's live map: the shared EasyWay basemap, the route on real road
/// geometry, the ordered stops with the active pickup raised, and the captain's
/// own interpolated vehicle. Reference and actions live in the pickup panel
/// below; the map carries only what has to sit on the road.
class CaptainTripMap extends StatefulWidget {
  const CaptainTripMap({
    super.key,
    required this.route,
    required this.fix,
    required this.progress,
    required this.activePickup,
    this.bottomInset = 0,
  });

  final List<LatLng> route;
  final CaptainLocationFix? fix;
  final RouteProgressSnapshot? progress;

  /// The active pickup stop's coordinate, drawn with a raised pin.
  final LatLng? activePickup;

  /// Height of the panel covering the map's bottom, so the camera frames the
  /// route above it and the chrome rides over it.
  final double bottomInset;

  @override
  State<CaptainTripMap> createState() => _CaptainTripMapState();
}

class _CaptainTripMapState extends State<CaptainTripMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final CaptainMapRoad _road = CaptainMapRoad();
  late final CaptainMapCamera _camera;
  late final CaptainMapVehicle _vehicleLayer;
  double _zoom = 13;

  @override
  void initState() {
    super.initState();
    _camera = CaptainMapCamera(vsync: this, controller: _mapController);
    _vehicleLayer = CaptainMapVehicle(vsync: this)..addListener(_follow);
    _road.addListener(_onRoadLoaded);
    _vehicleLayer.feed(widget.fix);
    _road.sync(widget.route);
  }

  @override
  void didUpdateWidget(CaptainTripMap old) {
    super.didUpdateWidget(old);
    _vehicleLayer.feed(widget.fix);
    final before = _road.signature;
    _road.sync(widget.route);
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
    final fix = widget.fix;
    return fix == null ? null : LatLng(fix.latitude, fix.longitude);
  }

  void _follow() {
    final sample = _vehicleLayer.sample;
    if (sample == null) return;
    _camera.followTo(LatLng(sample.latitude, sample.longitude));
  }

  void _fit() => _camera.fit(_road.points, _vehicle, widget.bottomInset);

  @override
  Widget build(BuildContext context) {
    final route = _road.points;
    final center = _vehicle ?? (route.isNotEmpty ? route.first : null);

    if (center == null) {
      return const MapEmptyPanel(
        title: 'الخريطة غير متاحة',
        message: 'لا توجد إحداثيات لمسار هذه الرحلة بعد.',
      );
    }

    return Stack(
      children: [
        CaptainMapSurface(
          controller: _mapController,
          center: center,
          zoom: _zoom,
          initialFit: _camera.fitFor(route, _vehicle, widget.bottomInset),
          route: route,
          progress: widget.progress,
          vehicle: _vehicleLayer,
          activePickup: widget.activePickup,
          onMapReady: _camera.markReady,
          onMapEvent: _onMapEvent,
          onPositionChanged: _onPositionChanged,
        ),
        CaptainMapChrome(
          bottomInset: widget.bottomInset,
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
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if ((camera.zoom - _zoom).abs() < 0.25) return;
    setState(() => _zoom = camera.zoom);
  }

  void _onMapEvent(MapEvent event) {
    if (_camera.breaksFollow(event)) setState(_camera.stopFollowing);
  }
}
