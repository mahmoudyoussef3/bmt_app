import 'dart:math' as math;

import '../geo_math.dart';
import 'route_stop.dart';

/// Result of projecting a GPS position onto the route polyline.
class RouteProjection {
  const RouteProjection({
    required this.alongTrackMeters,
    required this.crossTrackMeters,
    required this.segmentIndex,
  });

  /// Distance from the route start to the projected point, along the route.
  final double alongTrackMeters;

  /// Perpendicular distance from the position to the route.
  final double crossTrackMeters;

  final int segmentIndex;
}

/// Precomputed polyline geometry over the ordered route stops.
///
/// Uses a local equirectangular approximation per segment, which is accurate
/// to well under a meter at the segment lengths bus routes use.
class RouteGeometry {
  RouteGeometry(Iterable<RouteStop> allStops)
    : stops = allStops.where((s) => s.hasCoordinates).toList() {
    cumulativeMeters = List.filled(stops.length, 0);
    for (var i = 1; i < stops.length; i++) {
      cumulativeMeters[i] =
          cumulativeMeters[i - 1] +
          GeoMath.distanceMeters(
            stops[i - 1].latitude,
            stops[i - 1].longitude,
            stops[i].latitude,
            stops[i].longitude,
          );
    }
  }

  /// Stops with valid coordinates, in route order.
  final List<RouteStop> stops;

  /// Along-route distance from the first stop to each stop.
  late final List<double> cumulativeMeters;

  double get totalMeters =>
      cumulativeMeters.isEmpty ? 0 : cumulativeMeters.last;

  bool get isTrackable => stops.length >= 2 && totalMeters > 0;

  /// Straight-line distance from a position to a stop.
  double distanceToStop(int index, double latitude, double longitude) {
    final stop = stops[index];
    return GeoMath.distanceMeters(
      latitude,
      longitude,
      stop.latitude,
      stop.longitude,
    );
  }

  /// Projects a position onto the route. Candidates that keep the vehicle at
  /// or ahead of [minAlongMeters] (minus [backtrackToleranceMeters]) win over
  /// globally closer ones, so loop-shaped routes cannot snap the bus
  /// backwards onto an earlier leg it already covered.
  RouteProjection? project(
    double latitude,
    double longitude, {
    double minAlongMeters = 0,
    double backtrackToleranceMeters = 0,
  }) {
    if (stops.length < 2) return null;
    RouteProjection? forward;
    RouteProjection? global;
    final floor = minAlongMeters - backtrackToleranceMeters;
    for (var i = 0; i < stops.length - 1; i++) {
      final candidate = _projectOntoSegment(i, latitude, longitude);
      if (global == null ||
          candidate.crossTrackMeters < global.crossTrackMeters) {
        global = candidate;
      }
      if (candidate.alongTrackMeters >= floor &&
          (forward == null ||
              candidate.crossTrackMeters < forward.crossTrackMeters)) {
        forward = candidate;
      }
    }
    return forward ?? global;
  }

  RouteProjection _projectOntoSegment(
    int index,
    double latitude,
    double longitude,
  ) {
    final a = stops[index];
    final b = stops[index + 1];
    
    final metersPerLat = 111132.0;
    final metersPerLng =
        111320.0 * math.cos(((a.latitude + b.latitude) / 2) * math.pi / 180);
    final abX = (b.longitude - a.longitude) * metersPerLng;
    final abY = (b.latitude - a.latitude) * metersPerLat;
    final apX = (longitude - a.longitude) * metersPerLng;
    final apY = (latitude - a.latitude) * metersPerLat;
    final lengthSq = abX * abX + abY * abY;
    final t = lengthSq == 0
        ? 0.0
        : ((apX * abX + apY * abY) / lengthSq).clamp(0.0, 1.0);
    final dx = apX - abX * t;
    final dy = apY - abY * t;
    return RouteProjection(
      alongTrackMeters: cumulativeMeters[index] + math.sqrt(lengthSq) * t,
      crossTrackMeters: math.sqrt(dx * dx + dy * dy),
      segmentIndex: index,
    );
  }
}
