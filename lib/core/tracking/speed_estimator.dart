import 'geo_math.dart';
import 'tracking_config.dart';
import 'vehicle_fix.dart';

/// Produces a stable ground speed in km/h from noisy fixes.
///
/// Prefers the device-reported speed; when the device omits it, derives one
/// from displacement over time between consecutive fixes. Either source is
/// exponentially smoothed so the displayed speed does not flicker.
class SpeedEstimator {
  SpeedEstimator(this._config);

  final TrackingConfig _config;

  double _smoothedKmh = 0;
  bool _hasSample = false;

  double get currentKmh => _smoothedKmh;

  /// Folds the next accepted fix into the estimate and returns the updated
  /// smoothed speed in km/h.
  double update(VehicleFix? previous, VehicleFix next) {
    final raw = _rawKmh(previous, next);
    if (raw == null) return _smoothedKmh;

    if (!_hasSample) {
      _smoothedKmh = raw;
      _hasSample = true;
    } else {
      final alpha = _config.speedSmoothing;
      _smoothedKmh = alpha * raw + (1 - alpha) * _smoothedKmh;
    }
    return _smoothedKmh;
  }

  void reset() {
    _smoothedKmh = 0;
    _hasSample = false;
  }

  double? _rawKmh(VehicleFix? previous, VehicleFix next) {
    if (next.hasValidSpeed) return next.speedMetersPerSecond! * 3.6;
    if (previous == null) return null;

    final seconds =
        next.recordedAt.difference(previous.recordedAt).inMilliseconds / 1000;
    if (seconds <= 0) return null;

    final meters = GeoMath.distanceMeters(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );
    return meters / seconds * 3.6;
  }
}
