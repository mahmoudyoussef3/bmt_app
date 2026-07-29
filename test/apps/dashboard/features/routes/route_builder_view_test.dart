import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_route_geometry_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/search_places_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/route_builder_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_builder/route_builder_view.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_builder/route_stop_card.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';

/// Offline provider: search returns nothing, directions answer instantly with
/// one 10-minute leg per hop.
class _FakeGeoService implements GeoService {
  @override
  bool get enabled => true;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async {
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

void main() {
  late RouteBuilderCubit cubit;
  OperationRoute? saved;
  var cancelled = false;

  setUp(() {
    saved = null;
    cancelled = false;
    final geo = _FakeGeoService();
    dashboardDi.registerFactory<RouteBuilderCubit>(
      () => cubit = RouteBuilderCubit(GetRouteGeometryUseCase(geo)),
    );
    dashboardDi.registerLazySingleton<SearchPlacesUseCase>(
      () => SearchPlacesUseCase(geo),
    );
  });

  tearDown(() => dashboardDi.reset());

  Future<void> pumpBuilder(
    WidgetTester tester, {
    OperationRoute? route,
    bool saving = false,
    String saveError = '',
  }) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: RouteBuilderView(
              route: route,
              existingCodes: const ['RT-01'],
              saving: saving,
              saveError: saveError,
              onCancel: () => cancelled = true,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('opens on the two questions a route actually is', (tester) async {
    await pumpBuilder(tester);

    expect(find.text('مسار جديد'), findsOneWidget);
    expect(find.text('نقطة الانطلاق'), findsWidgets);
    expect(find.text('الوجهة النهائية'), findsWidgets);
    expect(find.text('مسار مباشر'), findsOneWidget);
    // Nothing to calculate yet, and nothing to save.
    expect(find.text('بانتظار تحديد النقطتين'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('names, measures and unlocks the save once both ends are set', (
    tester,
  ) async {
    await pumpBuilder(tester);

    cubit.selectPlace(0, _place('Banha, QL, Egypt', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo, Egypt', 30.04, 31.23));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Banha - Cairo'), findsWidgets);
    expect(find.text('5.0 كم'), findsOneWidget);
    expect(find.text('10 د'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('حفظ المسار'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Banha - Cairo');
    expect(saved!.routeCode, 'RT-02');
    expect(saved!.stations, hasLength(2));
    expect(saved!.startCity, 'Banha');
  });

  testWidgets('states the next thing to do, not a checklist', (tester) async {
    await pumpBuilder(tester);

    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('حدد الوجهة النهائية'), findsOneWidget);
  });

  testWidgets('arming the map announces which point the next tap places', (
    tester,
  ) async {
    await pumpBuilder(tester);

    cubit.pickOnMap(0);
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.textContaining('اضغط على الخريطة لتحديد موقع'),
      findsOneWidget,
    );

    cubit.placeOnMap(const GeoPoint(30.46, 31.18));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('اضغط على الخريطة لتحديد موقع'), findsNothing);
  });

  testWidgets('a stop carries its own boarding rule and dwell time', (
    tester,
  ) async {
    await pumpBuilder(tester);

    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    cubit.addStop();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 محطة في الطريق'), findsOneWidget);
    expect(find.text('صعود ونزول'), findsOneWidget);
    expect(find.text('0 د'), findsOneWidget);

    await tester.tap(find.text('نزول فقط'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      cubit.state.draft.toRoute().stations[1].pickupAllowed,
      isFalse,
    );
  });

  testWidgets('stop cards drag by list position, not by route position', (
    tester,
  ) async {
    await pumpBuilder(tester);

    cubit.selectPlace(0, _place('Banha', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo', 30.04, 31.23));
    cubit.addStop();
    cubit.addStop();
    await tester.pump(const Duration(milliseconds: 50));

    final cards = tester
        .widgetList<RouteStopCard>(find.byType(RouteStopCard))
        .toList();

    expect(cards, hasLength(2));
    // Route positions 1 and 2 are rows 0 and 1 of the reorderable list; giving
    // the drag listener the route position would drag the wrong row.
    expect(cards.map((card) => card.index).toList(), [1, 2]);
    expect(cards.map((card) => card.dragIndex).toList(), [0, 1]);
  });

  testWidgets('a rejected save keeps the draft and explains itself', (
    tester,
  ) async {
    await pumpBuilder(tester, saveError: 'كود المسار مستخدم بالفعل في مكتبك.');

    expect(find.text('كود المسار مستخدم بالفعل في مكتبك.'), findsOneWidget);
    expect(find.text('نقطة الانطلاق'), findsWidgets);
  });

  testWidgets('while saving, the bar says so and refuses a second submit', (
    tester,
  ) async {
    await pumpBuilder(tester, saving: true);

    expect(find.text('جارٍ الحفظ...'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('إلغاء'));
    await tester.pump();
    expect(cancelled, isFalse, reason: 'cancel is disabled mid-save');
  });

  testWidgets('editing loads the route and offers to save the changes', (
    tester,
  ) async {
    await pumpBuilder(
      tester,
      route: const OperationRoute(
        id: 'route-1',
        routeCode: 'RT-07',
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
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('تعديل المسار'), findsOneWidget);
    expect(find.text('حفظ التعديلات'), findsOneWidget);

    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pump();

    expect(saved!.id, 'route-1');
    expect(saved!.stations.map((station) => station.id).toList(), ['a', 'b']);
  });
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('route-builder-save')));
