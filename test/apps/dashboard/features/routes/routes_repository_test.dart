import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/data/datasources/mock_routes_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/routes/data/models/operation_route_model.dart';
import 'package:bmt_app/apps/dashboard/features/routes/data/repositories/routes_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/add_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/create_route_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/delete_route_station_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_operation_routes_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/update_route_station_usecase.dart';

void main() {
  group('Routes clean architecture chain', () {
    test('loads visual route operations data', () async {
      final repository = RoutesRepositoryImpl(MockRoutesDatasource());
      final getRoutes = GetOperationRoutesUseCase(repository);

      final routes = await getRoutes();

      expect(routes, isNotEmpty);
      expect(routes.first.name, 'بنها - القرية الذكية');
      expect(routes.first.stations, hasLength(4));
      expect(routes.first.stations.first.name, 'محطة بنها الرئيسية');
    });

    test('adds, edits, reorders, and deletes stations locally', () async {
      final repository = RoutesRepositoryImpl(MockRoutesDatasource());
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
          order: 0,
        ),
      );
      expect(added.stations.last.name, 'محطة اختبار');

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
      final repository = RoutesRepositoryImpl(MockRoutesDatasource());
      final createRoute = CreateRouteUseCase(repository);

      final created = await createRoute(_newRoute);

      expect(created.id, isNotEmpty);
      expect(created.status, OperationRouteStatus.draft);
      expect(
        created.stations.map((station) => station.name),
        contains('Station 1'),
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
  });
}

const _newRoute = OperationRoute(
  id: '',
  name: 'مسار اختبار',
  startCity: 'بنها',
  endCity: 'القاهرة',
  duration: '٦٠ دقيقة',
  distance: '٥٥ كم',
  tripsCount: 0,
  status: OperationRouteStatus.draft,
  stations: [
    RouteStation(
      id: 'draft-1',
      name: 'Station 1',
      area: 'بنها',
      arrivalOffset: '٠ دقيقة',
      order: 1,
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
