import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/geo/ors_geo_service.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_geometry_cache.dart';

/// Loads real road geometry for a route's stops via the shared [GeoService].
///
/// Never throws and never blocks the UI: results come from the LRU cache when
/// possible, concurrent requests for the same stops share one ORS call, and
/// any failure (network, quota, missing key) resolves to `null` so the map
/// falls back to its straight-line polyline.
class RouteGeometryService {
  RouteGeometryService._();

  static final RouteGeometryService instance = RouteGeometryService._();

  GeoService? _geoService;
  final Map<String, Future<RoadRoute?>> _inFlight = {};

  GeoService get _service => _geoService ??= OrsGeoService();

  /// Overrides the provider in tests. Passing `null` restores the default.
  set debugGeoService(GeoService? service) => _geoService = service;

  /// Cached result for [stops], if a previous load already resolved it.
  /// Lets the map render road geometry on first frame without a loading pass.
  RoadRoute? cached(List<LatLng> stops) {
    if (stops.length < 2) return null;
    return RouteGeometryCache.instance.get(
      RouteGeometryCache.signatureFor(stops),
    );
  }

  /// Resolves road geometry for [stops], or `null` when unavailable.
  Future<RoadRoute?> load(List<LatLng> stops) {
    if (stops.length < 2 || !_service.enabled) {
      return Future.value(null);
    }

    final signature = RouteGeometryCache.signatureFor(stops);
    final hit = RouteGeometryCache.instance.get(signature);
    if (hit != null) return Future.value(hit);

    return _inFlight.putIfAbsent(signature, () async {
      try {
        final geometry = await _service.directions(
          stops
              .map((point) => GeoPoint(point.latitude, point.longitude))
              .toList(growable: false),
        );
        if (geometry.path.length < 2) return null;

        final route = RoadRoute(
          points: geometry.path
              .map((point) => LatLng(point.lat, point.lng))
              .toList(growable: false),
          distanceMeters: geometry.totalDistanceMeters,
          durationSeconds: geometry.totalDurationSeconds,
        );
        RouteGeometryCache.instance.put(signature, route);
        return route;
      } on Exception {
        return null;
      } finally {
        _inFlight.remove(signature);
      }
    });
  }
}
