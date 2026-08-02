import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/data/datasources/routes_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/routes/data/models/operation_route_model.dart';
import 'package:bmt_app/apps/dashboard/features/routes/data/repositories/routes_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/add_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/create_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_operation_routes_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_state.dart';

void main() {
  group('Routes clean architecture chain', () {
    test('loads complete route operations data', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);

      final routes = await getRoutes();

      expect(routes, hasLength(greaterThanOrEqualTo(10)));
      expect(routes.first.name, 'بنها - القرية الذكية');
      expect(routes.first.stations.length, inInclusiveRange(5, 10));
      expect(routes.first.stations.first.notes, isNotEmpty);
      expect(routes.first.stations.first.departureOffset, isNotEmpty);
      expect(routes.first.stations.first.locationDescription, isNotEmpty);
    });

    test('adds, edits, reorders, and deletes stations locally', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);
      final addStation = AddRouteStationUseCase(repository);
      final updateStation = UpdateRouteStationUseCase(repository);
      final reorderStations = ReorderRouteStationsUseCase(repository);
      final deleteStation = DeleteRouteStationUseCase(repository);

      final route = (await getRoutes()).first;
      final added = await addStation(
        route.id,
        const RouteStation(
          id: '',
          name: 'محطة اختبار',
          area: 'منطقة اختبار',
          arrivalOffset: '٩٠ دقيقة',
          notes: 'ملاحظة اختبار',
          order: 0,
        ),
      );
      expect(added.stations.last.name, 'محطة اختبار');
      expect(added.stations.last.notes, 'ملاحظة اختبار');

      final editedStation = added.stations.last.copyWith(name: 'محطة معدلة');
      final edited = await updateStation(added.id, editedStation);
      expect(edited.stations.last.name, 'محطة معدلة');

      final reordered = await reorderStations(
        edited.id,
        edited.stations.length - 1,
        0,
      );
      expect(reordered.stations.first.name, 'محطة معدلة');
      expect(reordered.stations.first.order, 1);

      await deleteStation(reordered.id, reordered.stations.first.id);
      final afterDelete = (await getRoutes()).firstWhere(
        (item) => item.id == route.id,
      );
      expect(
        afterDelete.stations.any((station) => station.name == 'محطة معدلة'),
        isFalse,
      );
    });

    test('creates route through use case', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final createRoute = CreateRouteUseCase(repository);

      final created = await createRoute(_newRoute);

      expect(created.id, isNotEmpty);
      expect(created.status, OperationRouteStatus.draft);
      expect(
        created.stations.map((station) => station.name),
        contains('محطة اختبار ١'),
      );
      expect(created.stations.first.id, isNotEmpty);
    });

    test('duplicates and archives route through use cases', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);
      final createRoute = CreateRouteUseCase(repository);
      final updateRoute = UpdateRouteUseCase(repository);

      final original = (await getRoutes()).first;
      final duplicate = await createRoute(
        original.copyWith(
          id: '',
          routeCode: '${original.routeCode}-COPY',
          name: '${original.name} - نسخة',
          status: OperationRouteStatus.draft,
          stations: original.stations
              .map((station) => station.copyWith(id: ''))
              .toList(),
        ),
      );

      expect(duplicate.id, isNot(original.id));
      expect(duplicate.name, contains('نسخة'));
      expect(duplicate.status, OperationRouteStatus.draft);
      expect(duplicate.stations.first.id, isNotEmpty);

      final archived = await updateRoute(
        original.copyWith(status: OperationRouteStatus.archived),
      );
      expect(archived.status, OperationRouteStatus.archived);
    });

    test('updates route status locally for pause and archive flows', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);
      final updateRoute = UpdateRouteUseCase(repository);

      final original = (await getRoutes()).first;
      final paused = await updateRoute(
        original.copyWith(status: OperationRouteStatus.paused),
      );
      expect(paused.status.label, 'متوقف');

      final archived = await updateRoute(
        paused.copyWith(status: OperationRouteStatus.archived),
      );
      final routes = await getRoutes();
      expect(archived.status.label, 'مؤرشف');
      expect(
        routes.firstWhere((route) => route.id == original.id).status,
        OperationRouteStatus.archived,
      );
    });

    test('maps datasource failures to Arabic repository error', () {
      final repository = RoutesRepositoryImpl(_FailingRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);

      expect(
        getRoutes.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل المسارات'),
          ),
        ),
      );
    });

    test('handles empty routes list without throwing exceptions', () {
      const state = RoutesLoaded(routes: [], selectedRouteId: '');

      expect(state.selectedRoute, isNotNull);
      expect(state.selectedRoute.id, isEmpty);
      expect(state.filteredRoutes, isEmpty);
      expect(state.stopLibrary.isEmpty, isTrue);
    });

    test('search reaches the stops, not just the route name', () async {
      final repository = RoutesRepositoryImpl(_MockRoutesDatasource());
      final routes = await GetOperationRoutesUseCase(repository)();
      final stopName = routes.first.stations[1].name;

      final state = RoutesLoaded(
        routes: routes,
        selectedRouteId: routes.first.id,
        searchQuery: stopName,
      );

      // An operator looking for "the line through Mostorod" is looking for a
      // stop; the old filter only matched name, code and the two endpoints.
      expect(
        state.filteredRoutes.map((route) => route.id),
        contains(routes.first.id),
      );
    });
  });
}

const _newRoute = OperationRoute(
  id: '',
  routeCode: 'TEST-001',
  name: 'مسار اختبار',
  startCity: 'بنها',
  endCity: 'القاهرة',
  duration: '٦٠ دقيقة',
  distance: '٥٥ كم',
  status: OperationRouteStatus.draft,
  stations: [
    RouteStation(
      id: 'draft-1',
      name: 'محطة اختبار ١',
      area: 'بنها',
      arrivalOffset: '٠ دقيقة',
      departureOffset: '٣ دقائق',
      locationDescription: 'أمام موقف بنها الرئيسي',
      notes: 'محطة بداية اختبارية',
      order: 1,
    ),
    RouteStation(
      id: 'draft-2',
      name: 'محطة اختبار ٢',
      area: 'القاهرة',
      arrivalOffset: '٦٠ دقيقة',
      departureOffset: '٦٣ دقيقة',
      locationDescription: 'أمام نقطة الوصول',
      notes: 'محطة نهاية اختبارية',
      order: 2,
    ),
  ],
  notes: [],
);

class _FailingRoutesDatasource implements RoutesDatasource {
  @override
  Future<OperationRouteModel> addStation(String routeId, RouteStation station) {
    throw StateError('failure');
  }

  @override
  Future<OperationRouteModel> createRoute(OperationRoute route) {
    throw StateError('failure');
  }

  @override
  Future<OperationRouteModel> deleteStation(String routeId, String stationId) {
    throw StateError('failure');
  }

  @override
  Future<void> deleteRoute(String routeId) {
    throw StateError('failure');
  }

  @override
  Future<List<OperationRouteModel>> fetchRoutes() {
    throw StateError('failure');
  }

  @override
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationRouteModel> updateRoute(OperationRoute route) {
    throw StateError('failure');
  }

  @override
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  ) {
    throw StateError('failure');
  }
}

class _MockRoutesDatasource implements RoutesDatasource {
  final List<OperationRouteModel> _routes = [];

  _MockRoutesDatasource() {
    // Seed 10 routes
    _routes.add(
      OperationRouteModel(
        id: 'route-1',
        routeCode: 'BNS-SV-001',
        name: 'بنها - القرية الذكية',
        startCity: 'بنها',
        endCity: 'القرية الذكية',
        duration: '٧٥ دقيقة',
        distance: '٧٦ كم',
        status: OperationRouteStatus.active,
        notes: const ['ملاحظة ١'],
        stations: List.generate(
          6,
          (index) => RouteStation(
            id: 'station-1-$index',
            name: 'محطة ${index + 1}',
            area: 'منطقة ${index + 1}',
            arrivalOffset: '${index * 15} دقيقة',
            departureOffset: '${index * 15 + 3} دقيقة',
            locationDescription: 'وصف الموقع ${index + 1}',
            notes: 'ملاحظة المحطة ${index + 1}',
            order: index + 1,
          ),
        ),
      ),
    );

    for (int i = 2; i <= 10; i++) {
      _routes.add(
        OperationRouteModel(
          id: 'route-$i',
          routeCode: 'ROUTE-$i',
          name: 'مسار $i',
          startCity: 'مدينة البداية $i',
          endCity: 'مدينة النهاية $i',
          duration: '٦٠ دقيقة',
          distance: '٥٠ كم',
          status: OperationRouteStatus.active,
          notes: const [],
          stations: [
            RouteStation(
              id: 'station-$i-1',
              name: 'محطة البداية',
              area: 'المنطقة',
              arrivalOffset: '٠ دقيقة',
              departureOffset: '٣ دقائق',
              locationDescription: 'وصف',
              notes: 'ملاحظات',
              order: 1,
            ),
          ],
        ),
      );
    }
  }

  @override
  Future<List<OperationRouteModel>> fetchRoutes() async {
    return List.from(_routes);
  }

  @override
  Future<OperationRouteModel> createRoute(OperationRoute route) async {
    final newRoute = OperationRouteModel(
      id: route.id.isEmpty
          ? 'route-new-${DateTime.now().millisecondsSinceEpoch}'
          : route.id,
      routeCode: route.routeCode,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      notes: route.notes,
      stations: route.stations
          .map(
            (s) => RouteStation(
              id: s.id.isEmpty
                  ? 'station-new-${DateTime.now().millisecondsSinceEpoch}'
                  : s.id,
              name: s.name,
              area: s.area,
              arrivalOffset: s.arrivalOffset,
              departureOffset: s.departureOffset,
              locationDescription: s.locationDescription,
              notes: s.notes,
              order: s.order,
              latitude: s.latitude,
              longitude: s.longitude,
              pickupAllowed: s.pickupAllowed,
              dropoffAllowed: s.dropoffAllowed,
              estimatedArrivalTime: s.estimatedArrivalTime,
            ),
          )
          .toList(),
    );
    _routes.add(newRoute);
    return newRoute;
  }

  @override
  Future<OperationRouteModel> updateRoute(OperationRoute route) async {
    final index = _routes.indexWhere((r) => r.id == route.id);
    if (index == -1) {
      throw StateError('Route not found');
    }
    final updated = OperationRouteModel.fromEntity(route);
    _routes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    _routes.removeWhere((route) => route.id == routeId);
  }

  @override
  Future<OperationRouteModel> addStation(
    String routeId,
    RouteStation station,
  ) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) {
      throw StateError('Route not found');
    }
    final route = _routes[index];
    final newStation = RouteStation(
      id: 'station-added-${DateTime.now().millisecondsSinceEpoch}',
      name: station.name,
      area: station.area,
      arrivalOffset: station.arrivalOffset,
      departureOffset: station.departureOffset,
      locationDescription: station.locationDescription,
      notes: station.notes,
      order: route.stations.length + 1,
    );
    final updatedStations = List<RouteStation>.from(route.stations)
      ..add(newStation);
    final updated = OperationRouteModel(
      id: route.id,
      routeCode: route.routeCode,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      notes: route.notes,
      stations: updatedStations,
    );
    _routes[index] = updated;
    return updated;
  }

  @override
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  ) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) {
      throw StateError('Route not found');
    }
    final route = _routes[index];
    final updatedStations = route.stations
        .map((s) => s.id == station.id ? station : s)
        .toList();
    final updated = OperationRouteModel(
      id: route.id,
      routeCode: route.routeCode,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      notes: route.notes,
      stations: updatedStations,
    );
    _routes[index] = updated;
    return updated;
  }

  @override
  Future<OperationRouteModel> deleteStation(
    String routeId,
    String stationId,
  ) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) {
      throw StateError('Route not found');
    }
    final route = _routes[index];
    final updatedStations = route.stations
        .where((s) => s.id != stationId)
        .toList();
    final updated = OperationRouteModel(
      id: route.id,
      routeCode: route.routeCode,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      notes: route.notes,
      stations: updatedStations,
    );
    _routes[index] = updated;
    return updated;
  }

  @override
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) {
      throw StateError('Route not found');
    }
    final route = _routes[index];
    final stations = List<RouteStation>.from(route.stations);
    final item = stations.removeAt(oldIndex);
    stations.insert(newIndex, item);

    // Update orders
    final reordered = <RouteStation>[];
    for (int i = 0; i < stations.length; i++) {
      reordered.add(stations[i].copyWith(order: i + 1));
    }

    final updated = OperationRouteModel(
      id: route.id,
      routeCode: route.routeCode,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      notes: route.notes,
      stations: reordered,
    );
    _routes[index] = updated;
    return updated;
  }
}
