import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/route_draft.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_route_geometry_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/route_builder_cubit.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';

/// Directions provider double. Every leg is 10 minutes / 5 km, so the schedule
/// the cubit derives is predictable.
class _FakeGeoService implements GeoService {
  _FakeGeoService({this.enabled = true, this.failure});

  @override
  final bool enabled;

  /// When set, [directions] throws it instead of answering.
  final Object? failure;

  int directionsCalls = 0;
  List<GeoPoint> lastRequest = const [];

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async {
    directionsCalls++;
    lastRequest = orderedPoints;
    if (failure != null) throw failure!;
    final legs = List.generate(
      orderedPoints.length - 1,
      (_) => const RouteLeg(distanceMeters: 5000, durationSeconds: 600),
    );
    return RouteGeometry(
      totalDistanceMeters: 5000.0 * legs.length,
      totalDurationSeconds: 600.0 * legs.length,
      legs: legs,
      path: orderedPoints,
    );
  }
}

GeoPlace _place(String label, double lat, double lng) =>
    GeoPlace(label: label, point: GeoPoint(lat, lng));

/// Longer than the cubit's 450ms recalculation debounce.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 700));

void main() {
  late _FakeGeoService geo;
  late RouteBuilderCubit cubit;

  RouteBuilderCubit build({_FakeGeoService? service}) {
    geo = service ?? _FakeGeoService();
    return cubit = RouteBuilderCubit(GetRouteGeometryUseCase(geo));
  }

  tearDown(() => cubit.close());

  test('a new route opens focused on its origin with a reserved code', () {
    build().start(existingCodes: const ['RT-01']);

    expect(cubit.state.draft.stops, hasLength(2));
    expect(cubit.state.draft.code, 'RT-02');
    expect(cubit.state.activeIndex, 0);
    expect(cubit.state.draft.isReady, isFalse);
  });

  test('resolving both endpoints calculates distance, duration and schedule', () async {
    build().start();

    cubit.selectPlace(0, _place('Banha, QL, Egypt', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo, Egypt', 30.04, 31.23));
    await _settle();

    final draft = cubit.state.draft;
    expect(geo.directionsCalls, 1, reason: 'the debounce coalesces both edits');
    expect(draft.distance, '5.0 كم');
    expect(draft.duration, '10 د');
    expect(draft.origin.departureOffset, '00:00');
    expect(draft.destination.arrivalOffset, '00:10');
    expect(cubit.state.path, hasLength(2));
    expect(cubit.state.calculating, isFalse);
    expect(draft.isReady, isTrue);
  });

  test('does not call the provider until every point is placed', () async {
    build().start();

    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    await _settle();

    expect(geo.directionsCalls, 0);
    expect(cubit.state.draft.hasMetrics, isFalse);
  });

  test('the map only places a point while it is armed', () {
    build().start();

    cubit.placeOnMap(const GeoPoint(30.1, 31.1));
    expect(cubit.state.draft.origin.isLocated, isFalse);

    cubit.pickOnMap(0);
    expect(cubit.state.picking, isTrue);

    cubit.placeOnMap(const GeoPoint(30.1, 31.1));
    expect(cubit.state.draft.origin.point, const GeoPoint(30.1, 31.1));
    expect(
      cubit.state.draft.origin.name,
      'نقطة الانطلاق',
      reason: 'a point placed on the map still needs a title to be saveable',
    );
    expect(cubit.state.picking, isFalse, reason: 'one tap, one point');
  });

  test('typing a name never disturbs the calculated totals', () async {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    await _settle();

    cubit.renameStop(0, 'موقف بنها');
    await _settle();

    expect(geo.directionsCalls, 1);
    expect(cubit.state.draft.distance, '5.0 كم');
    expect(cubit.state.draft.name, 'موقف بنها - Cairo');
  });

  test('adding a stop recalculates through it once it is placed', () async {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    await _settle();

    cubit.addStop();
    expect(cubit.state.activeIndex, 1, reason: 'the new stop opens for editing');
    cubit.selectPlace(1, _place('Qalyub', 30.18, 31.20));
    await _settle();

    expect(geo.directionsCalls, 2);
    expect(geo.lastRequest, hasLength(3));
    expect(cubit.state.draft.distance, '10 كم');
    expect(cubit.state.draft.destination.arrivalOffset, '00:20');
  });

  test('dwell time pushes the stops after it later', () async {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    cubit.addStop();
    cubit.selectPlace(1, _place('Qalyub', 30.18, 31.20));
    await _settle();

    cubit.setDwellMinutes(1, 7);
    await _settle();

    expect(cubit.state.draft.stops[1].departureOffset, '00:17');
    expect(cubit.state.draft.destination.arrivalOffset, '00:27');
  });

  test('reversing the direction re-runs the calculation the other way', () async {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    await _settle();

    cubit.swapEndpoints();
    await _settle();

    expect(cubit.state.draft.origin.name, 'Cairo');
    expect(cubit.state.draft.destination.name, 'Banha');
    expect(geo.lastRequest.first, const GeoPoint(30.04, 31.23));
  });

  test('a failed calculation surfaces a message and keeps the draft', () async {
    build(service: _FakeGeoService(failure: const GeoException('لا يوجد اتصال')))
        .start();

    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    await _settle();

    expect(cubit.state.geoError, 'لا يوجد اتصال');
    expect(cubit.state.calculating, isFalse);
    expect(cubit.state.draft.origin.name, 'Banha');
  });

  test('without a geo provider, totals are the operator\'s to enter', () async {
    build(service: _FakeGeoService(enabled: false)).start();

    cubit.pickOnMap(0);
    cubit.placeOnMap(const GeoPoint(30.46, 31.18));
    cubit.pickOnMap(1);
    cubit.placeOnMap(const GeoPoint(30.04, 31.23));
    await _settle();

    expect(geo.directionsCalls, 0);
    expect(cubit.state.draft.isReady, isFalse);

    cubit.setDistance('42 كم');
    cubit.setDuration('55 د');
    expect(cubit.state.draft.isReady, isTrue);
  });

  test('editing an existing route recalculates it immediately', () async {
    build().start(
      route: const OperationRoute(
        id: 'route-1',
        routeCode: 'RT-04',
        name: 'بنها - القاهرة',
        startCity: 'بنها',
        endCity: 'القاهرة',
        duration: '30 د',
        distance: '20 كم',
        status: OperationRouteStatus.active,
        stations: [
          RouteStation(
            id: 'a',
            name: 'بنها',
            area: 'القليوبية',
            arrivalOffset: '00:00',
            latitude: 30.46,
            longitude: 31.18,
            order: 1,
          ),
          RouteStation(
            id: 'b',
            name: 'القاهرة',
            area: 'القاهرة',
            arrivalOffset: '00:30',
            latitude: 30.04,
            longitude: 31.23,
            order: 2,
          ),
        ],
        notes: [],
      ),
    );

    expect(cubit.state.activeIndex, -1, reason: 'nothing is half-finished yet');
    expect(cubit.state.draft.isEditing, isTrue);
    await _settle();

    expect(geo.directionsCalls, 1);
    expect(cubit.state.draft.distance, '5.0 كم');
    expect(cubit.state.draft.toRoute().id, 'route-1');
  });

  test('removing a stop clears the focus it had', () async {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    cubit.addStop();
    cubit.selectPlace(1, _place('Qalyub', 30.18, 31.20));
    await _settle();

    cubit.removeStop(1);
    await _settle();

    expect(cubit.state.draft.stops, hasLength(2));
    expect(cubit.state.activeIndex, -1);
    expect(cubit.state.draft.distance, '5.0 كم');
  });

  test('the boarding rule of a stop is part of the saved route', () {
    build().start();
    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    cubit.addStop();
    cubit.selectPlace(1, _place('Qalyub', 30.18, 31.20));

    cubit.setBoarding(1, RouteStopBoarding.dropoffOnly);

    final station = cubit.state.draft.toRoute().stations[1];
    expect(station.pickupAllowed, isFalse);
    expect(station.dropoffAllowed, isTrue);
  });
}
