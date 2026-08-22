// Throwaway visual check — not part of the suite.
//
//     flutter test test/apps/dashboard/features/routes/_scratch_routes_screen_capture.dart --update-goldens
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
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
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/routes_list_view.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';

const _captureFont = 'CaptureArabic';

class _FakeRoutesRepository implements RoutesRepository {
  _FakeRoutesRepository(this.routes);
  final List<OperationRoute> routes;

  @override
  Future<List<OperationRoute>> getRoutes() async => routes;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeTripsRepository implements TripsRepository {
  _FakeTripsRepository(this.trips);
  final List<OperationTrip> trips;

  @override
  Future<List<OperationTrip>> getTrips() async => trips;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

OperationRoute _route({
  required String id,
  required String code,
  required String start,
  required String end,
  required String duration,
  required String distance,
  required OperationRouteStatus status,
  required int stationCount,
}) {
  return OperationRoute(
    id: id,
    routeCode: code,
    name: '$start - $end',
    startCity: start,
    endCity: end,
    duration: duration,
    distance: distance,
    status: status,
    stations: List.generate(
      stationCount,
      (i) => RouteStation(
        id: '$id-s$i',
        name: 'محطة $i',
        area: '',
        arrivalOffset: '',
        order: i + 1,
      ),
    ),
    notes: const [],
  );
}

final _routes = [
  _route(
    id: 'r1',
    code: 'RT-01',
    start: 'بنها',
    end: 'القرية الذكية',
    duration: '90 دقيقة',
    distance: '55 كم',
    status: OperationRouteStatus.active,
    stationCount: 5,
  ),
  _route(
    id: 'r2',
    code: 'RT-02',
    start: 'بنها',
    end: 'مدينة نصر',
    duration: '100 دقيقة',
    distance: '48 كم',
    status: OperationRouteStatus.active,
    stationCount: 4,
  ),
  _route(
    id: 'r3',
    code: 'RT-03',
    start: 'بنها',
    end: 'الشيراتون',
    duration: '95 دقيقة',
    distance: '52 كم',
    status: OperationRouteStatus.active,
    stationCount: 4,
  ),
  _route(
    id: 'r4',
    code: 'RT-04',
    start: 'بنها',
    end: 'المهندسين',
    duration: '110 دقيقة',
    distance: '50 كم',
    status: OperationRouteStatus.paused,
    stationCount: 5,
  ),
  _route(
    id: 'r5',
    code: 'RT-05',
    start: 'بنها',
    end: 'أكتوبر',
    duration: '125 دقيقة',
    distance: '70 كم',
    status: OperationRouteStatus.active,
    stationCount: 6,
  ),
];

OperationTrip _trip({
  required String id,
  required String routeId,
  required String route,
  required int daysFromNow,
  required double price,
  required int capacity,
  required int bookedSeats,
}) {
  final date = DateTime.now().add(Duration(days: daysFromNow));
  return OperationTrip(
    id: id,
    routeId: routeId,
    route: route,
    routePoints: const [],
    driverId: 'd-1',
    driver: 'محمد علي',
    vehicleId: 'v-1',
    vehicle: 'MEG-003',
    date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    departure: '07:30',
    arrival: '',
    status: OperationTripStatus.scheduled,
    capacity: capacity,
    ticketPrice: price,
    seats: List.generate(
      capacity,
      (i) => TripSeat(
        id: 's-$id-$i',
        label: '${i + 1}',
        row: i ~/ 4,
        column: i % 4,
        state: i < bookedSeats ? TripSeatState.paid : TripSeatState.available,
      ),
    ),
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

final _trips = [
  for (var w = 0; w < 10; w++)
    _trip(id: 't1-$w', routeId: 'r1', route: 'بنها ← القرية الذكية', daysFromNow: w, price: 75, capacity: 14, bookedSeats: 12),
  for (var w = 0; w < 10; w++)
    _trip(id: 't2-$w', routeId: 'r2', route: 'بنها ← مدينة نصر', daysFromNow: w, price: 80, capacity: 14, bookedSeats: 10),
  for (var w = 0; w < 8; w++)
    _trip(id: 't3-$w', routeId: 'r3', route: 'بنها ← الشيراتون', daysFromNow: w, price: 85, capacity: 14, bookedSeats: 7),
  for (var w = 0; w < 6; w++)
    _trip(id: 't4-$w', routeId: 'r4', route: 'بنها ← المهندسين', daysFromNow: w, price: 70, capacity: 14, bookedSeats: 6),
  for (var w = 0; w < 6; w++)
    _trip(id: 't5-$w', routeId: 'r5', route: 'بنها ← أكتوبر', daysFromNow: w, price: 90, capacity: 14, bookedSeats: 9),
];

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('scratch: routes screen, light', (tester) async {
    tester.view.physicalSize = const Size(2000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _FakeRoutesRepository(_routes);
    final cubit = RoutesCubit(
      getRoutes: GetOperationRoutesUseCase(repository),
      getTrips: GetOperationTripsUseCase(_FakeTripsRepository(_trips)),
      createRoute: CreateRouteUseCase(repository),
      updateRoute: UpdateRouteUseCase(repository),
      deleteRoute: DeleteRouteUseCase(repository),
      addStation: AddRouteStationUseCase(repository),
      updateStation: UpdateRouteStationUseCase(repository),
      deleteStation: DeleteRouteStationUseCase(repository),
      reorderStations: ReorderRouteStationsUseCase(repository),
    );
    await cubit.load();

    final theme = _themeWithHostFont();

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(key: key, child: child!),
        ),
        home: Scaffold(
          body: BlocProvider<RoutesCubit>.value(
            value: cubit,
            child: BlocBuilder<RoutesCubit, RoutesState>(
              builder: (context, state) => state is RoutesLoaded
                  ? RoutesListView(state: state)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('_captures/_scratch_routes_screen.png'),
    );
    await cubit.close();
  });
}

ThemeData _themeWithHostFont() {
  final scheme = dashboardLightColorScheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: DashboardLightColors.background,
    canvasColor: DashboardLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: DashboardLightColors.shadow,
    extensions: [AppSurfaceStyle.ewt(scheme)],
  );
}
