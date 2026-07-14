import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';

/// The map's camera: fitting the route, following the vehicle, and knowing when
/// the rider has taken over.
///
/// Follow mode is the subtle part. The camera must chase the bus, but the
/// moment a rider drags the map to look somewhere else it has to let go — and
/// stay let go — or the screen fights them. Programmatic moves (our own fits
/// and follows) must not be mistaken for that.
class TrackingMapCamera {
  TrackingMapCamera({required TickerProvider vsync, required this.controller})
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

  /// True when this event was the rider moving the map themselves, which ends
  /// follow mode.
  bool breaksFollow(MapEvent event) {
    return _follow &&
        event.source != MapEventSource.mapController &&
        event.source != MapEventSource.nonRotatedSizeChange &&
        event is MapEventWithMove;
  }

  void stopFollowing() => _follow = false;

  /// Keeps the vehicle centred at the rider's current zoom.
  void followTo(LatLng position) {
    if (!_follow || !_ready) return;
    _animator.animateTo(center: position, zoom: controller.camera.zoom);
  }

  /// Frames the whole route (plus the vehicle), leaving room for the sheet so
  /// the line never settles behind it.
  CameraFit? fitFor(List<LatLng> route, LatLng? vehicle, double sheetInset) {
    final points = [...route, ?vehicle];
    if (points.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: EdgeInsets.fromLTRB(48, 48, 48, 48 + sheetInset),
      maxZoom: 16,
    );
  }

  void fit(List<LatLng> route, LatLng? vehicle, double sheetInset) {
    final camera = fitFor(route, vehicle, sheetInset);
    if (camera != null) {
      _animator.animateFit(camera);
    } else if (route.isNotEmpty) {
      _animator.animateTo(center: route.first, zoom: 14);
    }
  }
}
