import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';

/// Place autocomplete for route endpoints and stops, backed by [GeoService].
class SearchPlacesUseCase {
  final GeoService _geo;
  const SearchPlacesUseCase(this._geo);

  bool get enabled => _geo.enabled;

  Future<List<GeoPlace>> call(String query, {GeoPoint? focus}) =>
      _geo.autocomplete(query, focus: focus);
}
