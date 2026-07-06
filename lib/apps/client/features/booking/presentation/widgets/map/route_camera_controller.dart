import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Animates a flutter_map camera instead of jumping it.
///
/// flutter_map's [MapController.move]/[MapController.fitCamera] are instant;
/// this wrapper tweens center + zoom with an ease curve so recentering,
/// entrance fits and bound changes all glide. Only one animation runs at a
/// time — starting a new one retargets the previous mid-flight.
class RouteCameraAnimator {
  RouteCameraAnimator({
    required TickerProvider vsync,
    required this.controller,
  }) : _animation = AnimationController(
         vsync: vsync,
         duration: const Duration(milliseconds: 650),
       ) {
    _animation.addListener(_tick);
  }

  final MapController controller;
  final AnimationController _animation;

  static const Curve _curve = Curves.easeInOutCubic;

  LatLng _fromCenter = const LatLng(0, 0);
  LatLng _toCenter = const LatLng(0, 0);
  double _fromZoom = 0;
  double _toZoom = 0;

  void _tick() {
    final t = _curve.transform(_animation.value);
    controller.move(
      LatLng(
        _fromCenter.latitude + (_toCenter.latitude - _fromCenter.latitude) * t,
        _fromCenter.longitude +
            (_toCenter.longitude - _fromCenter.longitude) * t,
      ),
      _fromZoom + (_toZoom - _fromZoom) * t,
    );
  }

  /// Smoothly fits [fit] (bounds + padding) into view.
  void animateFit(CameraFit fit) {
    final target = fit.fit(controller.camera);
    animateTo(center: target.center, zoom: target.zoom);
  }

  /// Smoothly moves the camera to [center] / [zoom].
  void animateTo({required LatLng center, required double zoom}) {
    _animation.stop();
    final camera = controller.camera;
    _fromCenter = camera.center;
    _fromZoom = camera.zoom;
    _toCenter = center;
    _toZoom = zoom;
    _animation.forward(from: 0);
  }

  /// Animated zoom step for the +/- controls.
  void animateZoomBy(double delta, {double min = 5, double max = 18}) {
    final camera = controller.camera;
    animateTo(
      center: camera.center,
      zoom: (camera.zoom + delta).clamp(min, max),
    );
  }

  void dispose() => _animation.dispose();
}
