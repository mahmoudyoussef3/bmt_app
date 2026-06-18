/// Plain, framework-free models for geocoding + directions results.
library;

/// A geographic coordinate. ORS uses [lon, lat] ordering on the wire; this app
/// keeps the conventional {lat, lng} and converts at the service boundary.
class GeoPoint {
  final double lat;
  final double lng;

  const GeoPoint(this.lat, this.lng);

  /// ORS expects coordinates as [longitude, latitude].
  List<double> toLonLat() => [lng, lat];

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// A geocoding autocomplete result.
class GeoPlace {
  final String label;
  final GeoPoint point;

  const GeoPlace({required this.label, required this.point});

  @override
  String toString() => label;
}

/// Travel distance/duration for one leg between two consecutive points.
class RouteLeg {
  final double distanceMeters;
  final double durationSeconds;

  const RouteLeg({required this.distanceMeters, required this.durationSeconds});
}

/// Full directions result over an ordered list of points.
class RouteGeometry {
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final List<RouteLeg> legs;

  const RouteGeometry({
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.legs,
  });
}

/// Thrown by the geo service on configuration or network failure, carrying a
/// user-facing Arabic message (no silent failures).
class GeoException implements Exception {
  final String message;
  const GeoException(this.message);

  @override
  String toString() => message;
}
