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
    } catch (e) {
      throw Exception('تعذر إضافة المحطة: $e');
    }
  }

  @override
  Future<OperationRoute> createRoute(OperationRoute route) async {
    try {
      return await _datasource.createRoute(route);
    } catch (e) {
      throw Exception('تعذر إنشاء المسار: $e');
    }
  }

  @override
  Future<OperationRoute> deleteStation(String routeId, String stationId) async {
    try {
      return await _datasource.deleteStation(routeId, stationId);
    } catch (e) {
      throw Exception('تعذر حذف المحطة: $e');
    }
  }

  @override
  Future<List<OperationRoute>> getRoutes() async {
    try {
      return await _datasource.fetchRoutes();
    } catch (e) {
      throw Exception('تعذر تحميل المسارات: $e');
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
    } catch (e) {
      throw Exception('تعذر ترتيب المحطات: $e');
    }
  }

  @override
  Future<OperationRoute> updateRoute(OperationRoute route) async {
    try {
      return await _datasource.updateRoute(route);
    } catch (e) {
      throw Exception('تعذر تعديل المسار: $e');
    }
  }

  @override
  Future<OperationRoute> updateStation(
    String routeId,
    RouteStation station,
  ) async {
    try {
      return await _datasource.updateStation(routeId, station);
    } catch (e) {
      throw Exception('تعذر تعديل المحطة: $e');
    }
  }
}
