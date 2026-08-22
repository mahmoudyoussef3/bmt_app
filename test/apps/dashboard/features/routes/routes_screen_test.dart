import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/repositories/routes_repository.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/add_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/create_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_operation_routes_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_state.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/routes_list_view.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';

const _banhaCairo = OperationRoute(
  id: 'route-1',
  routeCode: 'RT-01',
  name: 'بنها - القاهرة',
  startCity: 'بنها',
  endCity: 'القاهرة',
  duration: '1 س 10 د',
  distance: '62 كم',
  status: OperationRouteStatus.active,
  stations: [
    RouteStation(id: 'a', name: 'بنها', area: '', arrivalOffset: '', order: 1),
    RouteStation(
      id: 'b',
      name: 'شبين القناطر',
      area: '',
      arrivalOffset: '',
      order: 2,
    ),
    RouteStation(id: 'c', name: 'مسطرد', area: '', arrivalOffset: '', order: 3),
    RouteStation(
      id: 'd',
      name: 'القاهرة',
      area: '',
      arrivalOffset: '',
      order: 4,
    ),
  ],
  notes: [],
);

/// Endpoints as the geocoder returns them for Egypt: Latin, inside an
/// otherwise-Arabic console.
const _newCairoZefta = OperationRoute(
  id: 'r-2',
  routeCode: 'RT-02',
  name: 'New Cairo - Zefta',
  startCity: 'New Cairo',
  endCity: 'Zefta',
  duration: '1 س 40 د',
  distance: '125 كم',
  status: OperationRouteStatus.active,
  stations: [
    RouteStation(
      id: 'x',
      name: 'New Cairo',
      area: '',
      arrivalOffset: '',
      order: 1,
    ),
    RouteStation(id: 'y', name: 'Zefta', area: '', arrivalOffset: '', order: 2),
  ],
  notes: [],
);

/// The headline as [RouteDetailsView] builds it: each endpoint inside a
/// first-strong isolate so the arrow follows the RTL paragraph.
String _direction(String from, String to) =>
    '\u2068$from\u2069 ← \u2068$to\u2069';

/// Nothing here calls the repository — these screens render state — but
/// [RoutesCubit] needs its use cases, so they are wired to a repository that
/// throws if anyone actually reaches it.
class _UnusedRepository implements RoutesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the screen tests never hit the repository');
}

/// [RoutesCubit] loads trips alongside routes purely to compute the board's
/// derived stats (occupancy, weekly trips, price) — a failure here degrades
/// to an empty list rather than failing the load, so an empty answer is a
/// realistic double, not just a stub.
class _EmptyTripsRepository implements TripsRepository {
  @override
  Future<List<OperationTrip>> getTrips() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

RoutesCubit _cubit() {
  final repository = _UnusedRepository();
  return RoutesCubit(
    getRoutes: GetOperationRoutesUseCase(repository),
    getTrips: GetOperationTripsUseCase(_EmptyTripsRepository()),
    createRoute: CreateRouteUseCase(repository),
    updateRoute: UpdateRouteUseCase(repository),
    deleteRoute: DeleteRouteUseCase(repository),
    addStation: AddRouteStationUseCase(repository),
    updateStation: UpdateRouteStationUseCase(repository),
    deleteStation: DeleteRouteStationUseCase(repository),
    reorderStations: ReorderRouteStationsUseCase(repository),
  );
}

void main() {
  late RoutesCubit cubit;

  setUp(() => cubit = _cubit());
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(value: cubit, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('routes list', () {
    testWidgets('a table row shows the direction, stations and status', (
      tester,
    ) async {
      await pump(
        tester,
        RoutesListView(
          state: RoutesLoaded(
            routes: const [_banhaCairo],
            selectedRouteId: 'route-1',
          ),
        ),
      );

      // The direction is one Text.rich span, not a standalone Text per
      // endpoint — textContaining still matches inside its plain text.
      expect(find.textContaining('بنها'), findsWidgets);
      expect(find.textContaining('القاهرة'), findsWidgets);
      expect(find.text('4 محطات، 1 س 10 د'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.byTooltip('عرض التفاصيل'), findsOneWidget);
      expect(find.byTooltip('المزيد'), findsOneWidget);
    });

    testWidgets(
      'the empty state explains what a route is and how little it needs',
      (tester) async {
        await pump(
          tester,
          RoutesListView(
            state: RoutesLoaded(routes: const [], selectedRouteId: ''),
          ),
        );

        expect(find.text('ابدأ بإضافة أول مسار'), findsOneWidget);
        expect(find.textContaining('اختياري'), findsOneWidget);
        expect(find.text('إضافة مسار جديد'), findsWidgets);
      },
    );

    testWidgets('filtering to nothing offers a different message', (
      tester,
    ) async {
      await pump(
        tester,
        RoutesListView(
          state: RoutesLoaded(
            routes: const [_banhaCairo],
            selectedRouteId: 'route-1',
            searchQuery: 'طنطا',
          ),
        ),
      );

      expect(find.text('لا توجد مسارات مطابقة'), findsOneWidget);
    });
  });

  group('route details', () {
    testWidgets('leads with the direction and the point count', (tester) async {
      await pump(
        tester,
        RouteDetailsView(
          state: RoutesLoaded(
            routes: [_banhaCairo],
            selectedRouteId: 'route-1',
          ),
        ),
      );

      expect(find.text(_direction('بنها', 'القاهرة')), findsOneWidget);
      expect(find.textContaining('مسار نقل'), findsOneWidget);
      expect(find.text('نقاط المسار'), findsOneWidget);
      expect(find.text('إنشاء مسار العودة'), findsOneWidget);
    });

    /// The geocoder answers in English for most Egyptian places, so a route's
    /// endpoints are routinely Latin inside this otherwise-Arabic console.
    /// Two Latin names on either side of a bare `←` resolve the whole line
    /// left to right, which points the arrow back at the origin and announces
    /// the route backwards; the isolates around each endpoint keep the arrow
    /// on the RTL paragraph's terms.
    testWidgets('the direction survives Latin place names', (tester) async {
      await pump(
        tester,
        RouteDetailsView(
          state: RoutesLoaded(routes: [_newCairoZefta], selectedRouteId: 'r-2'),
        ),
      );

      expect(find.text(_direction('New Cairo', 'Zefta')), findsOneWidget);
      // The bare form is what reads backwards on screen.
      expect(find.text('New Cairo ← Zefta'), findsNothing);
    });

    testWidgets('an unpinned stop reads as unset, never as an error', (
      tester,
    ) async {
      await pump(
        tester,
        RouteDetailsView(
          state: RoutesLoaded(
            routes: [_banhaCairo],
            selectedRouteId: 'route-1',
          ),
        ),
      );

      // Four stops, none of them located: four neutral chips and no warning.
      expect(find.text('الموقع غير محدد'), findsNWidgets(4));
      expect(find.text('لا توجد مواقع محددة'), findsOneWidget);
      expect(find.textContaining('الحجز عليه متاح'), findsOneWidget);
    });

    testWidgets('the return leg opens the builder on the reversed route', (
      tester,
    ) async {
      cubit.emit(
        RoutesLoaded(routes: [_banhaCairo], selectedRouteId: 'route-1'),
      );
      await pump(
        tester,
        RouteDetailsView(
          state: RoutesLoaded(
            routes: [_banhaCairo],
            selectedRouteId: 'route-1',
          ),
        ),
      );

      await tester.tap(find.text('إنشاء مسار العودة'));
      await tester.pump();

      final state = cubit.state as RoutesLoaded;
      expect(state.view, RoutesView.form);
      expect(state.reverseOf, _banhaCairo);
      expect(
        state.editingRoute,
        isNull,
        reason: 'the return leg is a new route, never an edit of the outbound',
      );
    });
  });
}
