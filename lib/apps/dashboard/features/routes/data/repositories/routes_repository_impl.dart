import '../../domain/entities/operation_route.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_datasource.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesDatasource _datasource;

  const RoutesRepositoryImpl(this._datasource);

  @override
  Future<OperationRoute> addStation(
    String routeId,
    RouteStation station,
  ) async {
    try {
      return await _datasource.addStation(routeId, station);
    } catch (_) {
      throw Exception('تعذر إضافة المحطة');
    }
  }

  @override
  Future<OperationRoute> createRoute(OperationRoute route) async {
    try {
      return await _datasource.createRoute(route);
    } catch (_) {
      throw Exception('تعذر إنشاء المسار');
    }
  }

  @override
  Future<OperationRoute> deleteStation(String routeId, String stationId) async {
    try {
      return await _datasource.deleteStation(routeId, stationId);
    } catch (_) {
      throw Exception('تعذر حذف المحطة');
    }
  }

  @override
  Future<List<OperationRoute>> getRoutes() async {
    try {
      return await _datasource.fetchRoutes();
    } catch (_) {
      throw Exception('تعذر تحميل المسارات');
    }
  }

  @override
  Future<OperationRoute> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      return await _datasource.reorderStations(routeId, oldIndex, newIndex);
    } catch (_) {
      throw Exception('تعذر ترتيب المحطات');
    }
  }

  @override
  Future<OperationRoute> updateRoute(OperationRoute route) async {
    try {
      return await _datasource.updateRoute(route);
    } catch (_) {
      throw Exception('تعذر تعديل المسار');
    }
  }

  @override
  Future<OperationRoute> updateStation(
    String routeId,
    RouteStation station,
  ) async {
    try {
      return await _datasource.updateStation(routeId, station);
    } catch (_) {
      throw Exception('تعذر تعديل المحطة');
    }
  }
}
