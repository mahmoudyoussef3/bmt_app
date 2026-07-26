import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';

/// The captain map's camera: fitting the route, following the vehicle, and
/// letting go the moment the captain drags the map themselves.
///
/// A mirror of the client's tracking camera (both wrap the shared
/// [RouteCameraAnimator]) so the captain map behaves identically — it never
/// forces the camera to chase the bus once the captain has taken over.
class CaptainMapCamera {
  CaptainMapCamera({required TickerProvider vsync, required this.controller})
    : _animator = RouteCameraAnimator(vsync: vsync, controller: controller);

  final MapController controller;
  final RouteCameraAnimator _animator;

  bool _follow = true;
  bool _ready = false;

  bool get isFollowing => _follow;
  bool get isReady => _ready;

  void markReady() => _ready = true;
  void dispose() => _animator.dispose();
  void zoomBy(double delta) => _animator.animateZoomBy(delta);
  void resumeFollow() => _follow = true;
  void stopFollowing() => _follow = false;

  /// True when this event was the captain moving the map themselves.
  bool breaksFollow(MapEvent event) {
    return _follow &&
        event.source != MapEventSource.mapController &&
        event.source != MapEventSource.nonRotatedSizeChange &&
        event is MapEventWithMove;
  }

  void followTo(LatLng position) {
    if (!_follow || !_ready) return;
    _animator.animateTo(center: position, zoom: controller.camera.zoom);
  }

  CameraFit? fitFor(List<LatLng> route, LatLng? vehicle, double bottomInset) {
    final points = [...route, ?vehicle];
    if (points.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: EdgeInsets.fromLTRB(48, 48, 48, 48 + bottomInset),
      maxZoom: 16,
    );
  }

  void fit(List<LatLng> route, LatLng? vehicle, double bottomInset) {
    final camera = fitFor(route, vehicle, bottomInset);
    if (camera != null) {
      _animator.animateFit(camera);
    } else if (route.isNotEmpty) {
      _animator.animateTo(center: route.first, zoom: 14);
    } else if (vehicle != null) {
      _animator.animateTo(center: vehicle, zoom: 15);
    }
  }
}
