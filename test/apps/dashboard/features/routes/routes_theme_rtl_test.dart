import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/repositories/routes_repository.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/add_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/create_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_operation_routes_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_route_geometry_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/search_places_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/route_builder_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_state.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_builder/route_builder_view.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_timeline_node.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/routes_list_view.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class _OfflineGeoService implements GeoService {
  @override
  bool get enabled => false;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async =>
      throw const GeoException('offline');
}

class _UnusedRepository implements RoutesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _route = OperationRoute(
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
      area: 'القليوبية',
      arrivalOffset: '00:25',
      order: 2,
    ),
    RouteStation(
      id: 'c',
      name: 'القاهرة',
      area: '',
      arrivalOffset: '01:10',
      order: 3,
    ),
  ],
  notes: [],
);

const _loaded = RoutesLoaded(routes: [_route], selectedRouteId: 'route-1');

void main() {
  late RoutesCubit routes;

  setUp(() {
    final repository = _UnusedRepository();
    routes = RoutesCubit(
      getRoutes: GetOperationRoutesUseCase(repository),
      createRoute: CreateRouteUseCase(repository),
      updateRoute: UpdateRouteUseCase(repository),
      deleteRoute: DeleteRouteUseCase(repository),
      addStation: AddRouteStationUseCase(repository),
      updateStation: UpdateRouteStationUseCase(repository),
      deleteStation: DeleteRouteStationUseCase(repository),
      reorderStations: ReorderRouteStationsUseCase(repository),
    );
    final geo = _OfflineGeoService();
    dashboardDi.registerFactory<RouteBuilderCubit>(
      () => RouteBuilderCubit(GetRouteGeometryUseCase(geo)),
    );
    dashboardDi.registerLazySingleton<SearchPlacesUseCase>(
      () => SearchPlacesUseCase(geo),
    );
  });

  tearDown(() async {
    await routes.close();
    await dashboardDi.reset();
  });

  /// Pumps [child] in the real dashboard theme, RTL, at a desktop and a narrow
  /// width, and fails on any overflow or paint error either one produces.
  Future<void> pumpBothThemes(
    WidgetTester tester,
    Widget child, {
    required String label,
  }) async {
    for (final dark in [false, true]) {
      for (final size in [const Size(1440, 1200), const Size(720, 1400)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
            locale: const Locale('ar'),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: BlocProvider.value(value: routes, child: child),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: '$label · ${dark ? 'dark' : 'light'} · ${size.width.toInt()}px',
        );
      }
    }
  }

  testWidgets('the routes list survives both themes and both widths', (
    tester,
  ) async {
    await pumpBothThemes(
      tester,
      const RoutesListView(state: _loaded),
      label: 'routes list',
    );
  });

  testWidgets('route details survives both themes and both widths', (
    tester,
  ) async {
    await pumpBothThemes(
      tester,
      const RouteDetailsView(state: _loaded),
      label: 'route details',
    );
  });

  testWidgets('the builder survives both themes and both widths', (
    tester,
  ) async {
    await pumpBothThemes(
      tester,
      RouteBuilderView(
        route: _route,
        existingCodes: const ['RT-01'],
        library: _loaded.stopLibrary,
        saving: false,
        saveError: '',
        onCancel: () {},
        onSave: (_) {},
      ),
      label: 'route builder',
    );
  });

  testWidgets('the empty list survives both themes and both widths', (
    tester,
  ) async {
    await pumpBothThemes(
      tester,
      const RoutesListView(
        state: RoutesLoaded(routes: [], selectedRouteId: ''),
      ),
      label: 'empty routes list',
    );
  });

  testWidgets('the direction chain reads right-to-left under RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: const Scaffold(
            body: RouteDirectionChain(stops: ['بنها', 'مسطرد', 'القاهرة']),
          ),
        ),
      ),
    );
    await tester.pump();

    final text = tester.widget<Text>(find.byType(Text));
    final rendered = text.textSpan!.toPlainText();

    // U+2190 (←), not U+2192: in an RTL line the journey runs right to left, so
    // a Latin "→" between the names would render the route backwards.
    expect(rendered.contains('←'), isTrue);
    expect(rendered.contains('→'), isFalse);
    expect(rendered.indexOf('بنها'), lessThan(rendered.indexOf('القاهرة')));
  });
}
