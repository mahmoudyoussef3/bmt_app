import 'geo_models.dart';

/// Geocoding + directions provider abstraction. Implemented by [OrsGeoService]
/// but kept provider-agnostic so it can be swapped or mocked in tests.
abstract class GeoService {
  /// Whether a usable provider key is configured. When false, callers should
  /// fall back to manual entry instead of calling [autocomplete]/[directions].
  bool get enabled;

  /// Place autocomplete for the given [query], optionally biased toward [focus].
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus});

  /// Driving distance/duration over [orderedPoints] (start → … → end), with one
  /// [RouteLeg] per consecutive pair. Requires at least two points.
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints);
}
