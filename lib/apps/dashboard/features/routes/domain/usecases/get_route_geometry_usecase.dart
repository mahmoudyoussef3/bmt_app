import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';

/// Driving distance/duration (with per-leg segments) over ordered route points,
/// backed by [GeoService]. The presentation layer feeds the legs into
/// [RouteScheduleCalculator] to derive per-stop arrival/departure offsets.
class GetRouteGeometryUseCase {
  final GeoService _geo;
  const GetRouteGeometryUseCase(this._geo);

  bool get enabled => _geo.enabled;

  Future<RouteGeometry> call(List<GeoPoint> orderedPoints) =>
      _geo.directions(orderedPoints);
}
