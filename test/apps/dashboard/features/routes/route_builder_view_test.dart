import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/services/route_stop_library.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_route_geometry_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/search_places_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/route_builder_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_builder/route_builder_view.dart';
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
    RouteStopLibrary library = RouteStopLibrary.empty,
    bool saving = false,
    String saveError = '',
  }) async {
    tester.view.physicalSize = const Size(1400, 1400);
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
              library: library,
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

  /// Opens the stop the timeline row belongs to, types [name], confirms.
  Future<void> fillStop(
    WidgetTester tester,
    String rowText,
    String name,
  ) async {
    await tester.tap(find.text(rowText));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('route-stop-editor-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the two questions a route actually is', (tester) async {
    await pumpBuilder(tester);

    expect(find.text('مسار جديد'), findsOneWidget);
    expect(find.text('من'), findsOneWidget);
    expect(find.text('إلى'), findsOneWidget);
    expect(find.text('اضغط لتحديد نقطة الانطلاق'), findsOneWidget);
    expect(find.text('اضغط لتحديد الوجهة النهائية'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets(
    'two typed names are a saveable route — the map is never opened',
    (tester) async {
      await pumpBuilder(tester);

      await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');
      await fillStop(tester, 'اضغط لتحديد الوجهة النهائية', 'القاهرة');

      expect(find.text('بنها'), findsWidgets);
      expect(find.text('القاهرة'), findsWidgets);
      // Optional by design, and stated in the ordinary voice on both endpoints.
      expect(find.text('الموقع غير محدد'), findsNWidgets(2));
      expect(_saveButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('حفظ المسار'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.name, 'بنها - القاهرة');
      expect(saved!.routeCode, 'RT-02');
      expect(saved!.startCity, 'بنها');
      expect(saved!.endCity, 'القاهرة');
      expect(saved!.stations, hasLength(2));
      expect(saved!.stations.first.latitude, isNull);
    },
  );

  testWidgets('a stop is added into the gap it belongs in', (tester) async {
    await pumpBuilder(tester);
    await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');
    await fillStop(tester, 'اضغط لتحديد الوجهة النهائية', 'القاهرة');

    // The first "+ إضافة نقطة" is the gap under the origin.
    await tester.tap(find.text('إضافة نقطة').first);
    await tester.pumpAndSettle();
    expect(find.text('إضافة نقطة في الطريق'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'شبين القناطر');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('route-stop-editor-save')));
    await tester.pumpAndSettle();

    expect(cubit.state.draft.stops.map((stop) => stop.name).toList(), [
      'بنها',
      'شبين القناطر',
      'القاهرة',
    ]);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a cancelled stop dialog leaves no blank row behind', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');
    await fillStop(tester, 'اضغط لتحديد الوجهة النهائية', 'القاهرة');

    await tester.tap(find.text('إضافة نقطة').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('إلغاء')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(cubit.state.draft.stops, hasLength(2));
  });

  testWidgets('the stop editor asks for a name and calls the map optional', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await tester.tap(find.text('اضغط لتحديد نقطة الانطلاق'));
    await tester.pumpAndSettle();

    expect(find.text('اسم النقطة'), findsOneWidget);
    expect(find.text('الوصف أو العنوان (اختياري)'), findsOneWidget);
    expect(find.text('الموقع الجغرافي غير محدد'), findsOneWidget);
    expect(
      find.text('تحديد الموقع على الخريطة اختياري لتحسين تجربة العملاء.'),
      findsOneWidget,
    );
    expect(find.text('تحديد الموقع على الخريطة'), findsOneWidget);

    // A name is the one thing it will not do without.
    expect(find.text('اسم النقطة مطلوب'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('route-stop-editor-save')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('states the next thing to do, not a checklist', (tester) async {
    await pumpBuilder(tester);
    await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');

    expect(find.text('حدد الوجهة النهائية'), findsOneWidget);
  });

  testWidgets('the same place at both ends is refused, in words', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');
    await fillStop(tester, 'اضغط لتحديد الوجهة النهائية', 'بنها');

    expect(
      find.text('نقطة الانطلاق والوجهة نفس المكان — غيّر إحداهما'),
      findsOneWidget,
    );
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('the direction is stated, and reversing it is deliberate', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await fillStop(tester, 'اضغط لتحديد نقطة الانطلاق', 'بنها');
    await fillStop(tester, 'اضغط لتحديد الوجهة النهائية', 'القاهرة');

    expect(find.text('اتجاه المسار'), findsOneWidget);

    await tester.tap(find.text('عكس الاتجاه'));
    await tester.pumpAndSettle();

    expect(cubit.state.draft.origin.name, 'القاهرة');
    expect(cubit.state.draft.destination.name, 'بنها');
  });

  testWidgets('a stop the office already uses is offered instead of retyped', (
    tester,
  ) async {
    await pumpBuilder(
      tester,
      library: RouteStopLibrary.fromRoutes([
        const OperationRoute(
          id: 'r1',
          name: 'قديم',
          startCity: 'شبين القناطر',
          endCity: 'القاهرة',
          duration: '',
          distance: '',
          status: OperationRouteStatus.active,
          stations: [
            RouteStation(
              id: 's1',
              name: 'شبين القناطر',
              area: 'القليوبية',
              arrivalOffset: '',
              latitude: 30.31,
              longitude: 31.32,
              order: 1,
            ),
          ],
          notes: [],
        ),
      ]),
    );

    await tester.tap(find.text('اضغط لتحديد نقطة الانطلاق'));
    await tester.pumpAndSettle();

    expect(find.text('نقاط تستخدمها بالفعل'), findsOneWidget);
    await tester.tap(find.text('شبين القناطر').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('route-stop-editor-save')));
    await tester.pumpAndSettle();

    // Adopted whole: name, area and the coordinates that stop already had.
    expect(cubit.state.draft.origin.name, 'شبين القناطر');
    expect(cubit.state.draft.origin.point, const GeoPoint(30.31, 31.32));
  });

  testWidgets('measurements appear once every point is pinned', (tester) async {
    await pumpBuilder(tester);

    cubit.selectPlace(0, _place('Banha, QL, Egypt', 30.46, 31.18));
    cubit.selectPlace(1, _place('Cairo, Egypt', 30.04, 31.23));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.textContaining('5.0 كم'), findsOneWidget);
    expect(find.text('الموقع محدد'), findsNWidgets(2));
  });

  testWidgets('a rejected save keeps the draft and explains itself', (
    tester,
  ) async {
    await pumpBuilder(tester, saveError: 'كود المسار مستخدم بالفعل في مكتبك.');

    expect(find.text('كود المسار مستخدم بالفعل في مكتبك.'), findsOneWidget);
    expect(find.text('من'), findsOneWidget);
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

  testWidgets('a stop in the middle is dragged into a new place in the order', (
    tester,
  ) async {
    await pumpBuilder(
      tester,
      route: OperationRoute(
        id: 'route-2',
        routeCode: 'RT-08',
        name: 'بنها - القاهرة',
        startCity: 'بنها',
        endCity: 'القاهرة',
        duration: '',
        distance: '',
        status: OperationRouteStatus.active,
        stations: [
          for (final (index, name) in [
            'بنها',
            'شبين',
            'قليوب',
            'القاهرة',
          ].indexed)
            RouteStation(
              id: 's$index',
              name: name,
              area: 'القليوبية',
              arrivalOffset: '',
              order: index + 1,
            ),
        ],
        notes: const [],
      ),
    );

    // Only the two stops in the middle can be dragged; the endpoints are
    // rendered outside the reorderable region and have no grip at all.
    final handles = find.byIcon(Icons.drag_indicator_rounded);
    expect(handles, findsNWidgets(2));

    final first = tester.getCenter(handles.at(0));
    final second = tester.getCenter(handles.at(1));

    Future<void> dragHandle(Offset from, Offset to) async {
      final gesture = await tester.startGesture(from);
      await tester.pump();
      for (var step = 1; step <= 8; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 8)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await dragHandle(first, second);
    expect(cubit.state.draft.stops.map((stop) => stop.name).toList(), [
      'بنها',
      'قليوب',
      'شبين',
      'القاهرة',
    ]);

    // ...and back up again, which is the other half of the index arithmetic.
    await dragHandle(second, first);
    expect(cubit.state.draft.stops.map((stop) => stop.name).toList(), [
      'بنها',
      'شبين',
      'قليوب',
      'القاهرة',
    ]);
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

FilledButton _saveButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.byKey(const ValueKey('route-builder-save')),
);
