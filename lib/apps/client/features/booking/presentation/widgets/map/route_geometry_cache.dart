import 'dart:collection';

import 'package:latlong2/latlong.dart';

/// A resolved road route: the shape to draw plus the provider's travel totals.
class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

/// Session-wide LRU cache of decoded road geometry, keyed by the stop
/// signature. Static so results survive map remounts (e.g. reopening Route
/// Details) and no ORS request is ever repeated for the same stops.
class RouteGeometryCache {
  RouteGeometryCache({this.capacity = 24});

  static final RouteGeometryCache instance = RouteGeometryCache();

  final int capacity;
  final LinkedHashMap<String, RoadRoute> _entries = LinkedHashMap();

  /// Stable key for an ordered list of stops. 5 decimals ≈ 1m precision,
  /// matching what the map treats as "the same coordinate".
  static String signatureFor(List<LatLng> stops) => stops
      .map(
        (point) =>
            '${point.latitude.toStringAsFixed(5)},'
            '${point.longitude.toStringAsFixed(5)}',
      )
      .join('|');

  RoadRoute? get(String signature) {
    final hit = _entries.remove(signature);
    if (hit != null) _entries[signature] = hit; // Refresh LRU position.
    return hit;
  }

  void put(String signature, RoadRoute route) {
    _entries.remove(signature);
    _entries[signature] = route;
    if (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  int get length => _entries.length;

  void clear() => _entries.clear();
}
