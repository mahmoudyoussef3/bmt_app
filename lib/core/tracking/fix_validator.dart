import 'geo_math.dart';
import 'tracking_config.dart';
import 'vehicle_fix.dart';

/// Why a fix was rejected by [FixValidator].
enum FixRejection {
  invalidCoordinates,
  poorAccuracy,
  outOfOrder,
  implausibleJump,
}

/// Gatekeeper for incoming GPS fixes. Realtime channels can replay events,
/// devices emit (0,0) junk fixes, and urban canyons produce teleports —
/// none of those may reach the marker.
class FixValidator {
  const FixValidator(this._config);

  final TrackingConfig _config;

  /// Returns null when [next] may be applied after [previous], otherwise the
  /// reason it must be dropped.
  FixRejection? validate(VehicleFix? previous, VehicleFix next) {
    if (!_hasSaneCoordinates(next)) return FixRejection.invalidCoordinates;

    if (next.hasValidAccuracy &&
        next.accuracyMeters! > _config.maxAccuracyMeters) {
      return FixRejection.poorAccuracy;
    }

    if (previous == null) return null;

    if (!next.recordedAt.isAfter(previous.recordedAt)) {
      return FixRejection.outOfOrder;
    }

    final seconds =
        next.recordedAt.difference(previous.recordedAt).inMilliseconds / 1000;
    final meters = GeoMath.distanceMeters(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );
    if (meters / seconds > _config.maxPlausibleSpeedMps) {
      return FixRejection.implausibleJump;
    }

    return null;
  }

  bool _hasSaneCoordinates(VehicleFix fix) {
    if (!fix.latitude.isFinite || !fix.longitude.isFinite) return false;
    if (fix.latitude.abs() > 90 || fix.longitude.abs() > 180) return false;
    
    if (fix.latitude == 0 && fix.longitude == 0) return false;
    return true;
  }
}
