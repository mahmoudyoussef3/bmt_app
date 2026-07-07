import 'dart:math' as math;

/// Pure geodesic math shared by the tracking engine. All angles in degrees,
/// all distances in meters.
abstract final class GeoMath {
  static const double earthRadiusMeters = 6371000;

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;

  /// Great-circle distance between two coordinates (haversine).
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusMeters * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Initial bearing from point 1 to point 2, degrees clockwise from north
  /// in [0, 360).
  static double bearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final phi1 = _rad(lat1);
    final phi2 = _rad(lat2);
    final dLng = _rad(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
    return normalizeDegrees(_deg(math.atan2(y, x)));
  }

  /// Normalizes an angle into [0, 360).
  static double normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  /// Interpolates between two angles along the shortest arc, so 350° → 10°
  /// passes through 0° rather than sweeping backwards through 180°.
  static double lerpAngleDegrees(double from, double to, double t) {
    final a = normalizeDegrees(from);
    final b = normalizeDegrees(to);
    var delta = b - a;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return normalizeDegrees(a + delta * t);
  }

  /// Linear latitude interpolation.
  static double lerpLatitude(double from, double to, double t) =>
      from + (to - from) * t;

  /// Longitude interpolation taking the short way across the antimeridian
  /// (179° → -179° moves 2°, not 358°). Result stays in [-180, 180].
  static double lerpLongitude(double from, double to, double t) {
    var delta = to - from;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    var result = from + delta * t;
    if (result > 180) result -= 360;
    if (result < -180) result += 360;
    return result;
  }

  /// Ease-out cubic: fast start, gentle arrival. Used as the default
  /// animation curve so markers settle naturally onto new fixes.
  static double easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
}
