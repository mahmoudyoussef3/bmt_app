import 'package:latlong2/latlong.dart';

/// Pure geometry helpers for progressive route drawing and vehicle motion.
/// Framework-free so they stay cheap to test and safe to call every frame.
class RoutePathMath {
  const RoutePathMath._();

  static const Distance _distance = Distance();

  /// Cumulative meters from the first point to each point. First entry is 0.
  /// Precompute once per path; never inside an animation tick.
  static List<double> cumulativeDistances(List<LatLng> points) {
    if (points.isEmpty) return const [];
    final result = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      result[i] =
          result[i - 1] + _distance.distance(points[i - 1], points[i]);
    }
    return result;
  }

  /// The leading portion of [points] covering [fraction] (0..1) of the total
  /// length, ending in an interpolated tip so the reveal moves smoothly
  /// between vertices instead of jumping per segment.
  static List<LatLng> pathPrefix(
    List<LatLng> points,
    List<double> cumulative,
    double fraction,
  ) {
    if (points.length < 2 || fraction >= 1) return points;
    if (fraction <= 0) return const [];

    final target = cumulative.last * fraction;
    var end = 1;
    while (end < cumulative.length && cumulative[end] < target) {
      end++;
    }

    final prefix = points.sublist(0, end);
    final segmentStart = cumulative[end - 1];
    final segmentLength = cumulative[end] - segmentStart;
    if (segmentLength > 0) {
      final t = (target - segmentStart) / segmentLength;
      prefix.add(_lerp(points[end - 1], points[end], t));
    }
    return prefix;
  }

  /// Splits [points] into a traveled prefix and a remaining suffix at
  /// [fraction] (0..1) of the path's total length, sharing an interpolated
  /// cut point so the two halves meet without a gap. [fraction] is a share of
  /// the *drawn* path — pass a fraction already normalized elsewhere (e.g. a
  /// route-progress engine's own, possibly shorter, geometry) rather than an
  /// absolute meters value, since [points] may be road geometry whose total
  /// length differs from the geometry the fraction was computed against.
  static (List<LatLng>, List<LatLng>) splitAtFraction(
    List<LatLng> points,
    List<double> cumulative,
    double fraction,
  ) {
    if (points.length < 2 || fraction <= 0) return (const [], points);
    if (fraction >= 1) return (points, const []);

    final prefix = pathPrefix(points, cumulative, fraction);
    final cut = prefix.last;
    final target = cumulative.last * fraction;
    var end = 1;
    while (end < cumulative.length && cumulative[end] < target) {
      end++;
    }
    final suffix = [cut, ...points.sublist(end)];
    return (prefix, suffix);
  }

  /// Interpolates a compass heading along the shortest arc, so a vehicle
  /// turning from 350° to 10° sweeps 20° through north, not 340° backwards.
  static double lerpHeading(double from, double to, double t) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return (from + delta * t) % 360;
  }

  static LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Linear position interpolation for live vehicle motion between updates.
  static LatLng lerpPosition(LatLng from, LatLng to, double t) =>
      _lerp(from, to, t);
}
