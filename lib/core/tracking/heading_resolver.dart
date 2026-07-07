import 'geo_math.dart';
import 'tracking_config.dart';
import 'vehicle_fix.dart';

/// Decides which way the vehicle marker should point.
///
/// Priority:
/// 1. Device heading, when reported and the vehicle is actually moving
///    (GPS compasses spin randomly while stationary).
/// 2. Bearing of the path between the previous and next fix, when the
///    displacement is large enough to be real movement rather than jitter.
/// 3. The last known heading — a parked bus keeps facing where it stopped.
class HeadingResolver {
  HeadingResolver(this._config);

  final TrackingConfig _config;

  double _lastHeading = 0;

  double get currentHeading => _lastHeading;

  /// Resolves the heading for the next accepted fix given the smoothed
  /// [speedKmh], returning degrees clockwise from north in [0, 360).
  double resolve(VehicleFix? previous, VehicleFix next, double speedKmh) {
    final isMoving = speedKmh >= _config.movingSpeedThresholdKmh;

    if (next.hasValidHeading && isMoving) {
      _lastHeading = GeoMath.normalizeDegrees(next.headingDegrees!);
      return _lastHeading;
    }

    if (previous != null) {
      final meters = GeoMath.distanceMeters(
        previous.latitude,
        previous.longitude,
        next.latitude,
        next.longitude,
      );
      if (meters >= _config.minBearingDistanceMeters) {
        _lastHeading = GeoMath.bearingDegrees(
          previous.latitude,
          previous.longitude,
          next.latitude,
          next.longitude,
        );
        return _lastHeading;
      }
    }

    return _lastHeading;
  }

  void reset() => _lastHeading = 0;
}
