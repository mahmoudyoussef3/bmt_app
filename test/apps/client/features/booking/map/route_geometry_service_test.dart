import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_geometry_cache.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_geometry_service.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';

class _FakeGeoService implements GeoService {
  _FakeGeoService({this.fail = false});

  final bool fail;
  int calls = 0;

  @override
  bool get enabled => true;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async {
    calls++;
    if (fail) throw const GeoException('network down');
    return RouteGeometry(
      totalDistanceMeters: 12400,
      totalDurationSeconds: 1500,
      legs: const [],
      path: [
        orderedPoints.first,
        const GeoPoint(30.05, 31.24),
        orderedPoints.last,
      ],
    );
  }
}

void main() {
  final stops = [const LatLng(30.0444, 31.2357), const LatLng(30.0721, 31.2465)];

  setUp(RouteGeometryCache.instance.clear);
  tearDown(() => RouteGeometryService.instance.debugGeoService = null);

  test('loads road geometry and converts totals', () async {
    final fake = _FakeGeoService();
    RouteGeometryService.instance.debugGeoService = fake;

    final road = await RouteGeometryService.instance.load(stops);

    expect(road, isNotNull);
    expect(road!.points, hasLength(3));
    expect(road.distanceMeters, 12400);
    expect(road.durationSeconds, 1500);
  });

  test('serves repeat requests from cache without a second provider call',
      () async {
    final fake = _FakeGeoService();
    RouteGeometryService.instance.debugGeoService = fake;

    await RouteGeometryService.instance.load(stops);
    final again = await RouteGeometryService.instance.load(stops);
    final cached = RouteGeometryService.instance.cached(stops);

    expect(fake.calls, 1);
    expect(again, isNotNull);
    expect(cached, isNotNull);
  });

  test('shares one in-flight request between concurrent loads', () async {
    final fake = _FakeGeoService();
    RouteGeometryService.instance.debugGeoService = fake;

    final results = await Future.wait([
      RouteGeometryService.instance.load(stops),
      RouteGeometryService.instance.load(stops),
    ]);

    expect(fake.calls, 1);
    expect(results.whereType<RoadRoute>(), hasLength(2));
  });

  test('resolves null on provider failure instead of throwing', () async {
    RouteGeometryService.instance.debugGeoService = _FakeGeoService(fail: true);

    final road = await RouteGeometryService.instance.load(stops);

    expect(road, isNull);
  });

  test('returns null for fewer than two stops', () async {
    RouteGeometryService.instance.debugGeoService = _FakeGeoService();

    expect(
      await RouteGeometryService.instance.load([stops.first]),
      isNull,
    );
  });
}
