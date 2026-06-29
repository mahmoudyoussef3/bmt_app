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
      _validateStation(station);
      return await _datasource.addStation(routeId, station);
    } catch (e) {
      throw Exception('تعذر إضافة المحطة: $e');
    }
  }

  @override
  Future<OperationRoute> createRoute(OperationRoute route) async {
    try {
      final routes = await _datasource.fetchRoutes();
      _validateRoute(route, existingRoutes: routes);
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
  Future<void> deleteRoute(String routeId) async {
    try {
      await _datasource.deleteRoute(routeId);
    } catch (e) {
      throw Exception('تعذر حذف المسار: $e');
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
      final routes = await _datasource.fetchRoutes();
      _validateRoute(route, existingRoutes: routes);
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
      _validateStation(station);
      return await _datasource.updateStation(routeId, station);
    } catch (e) {
      throw Exception('تعذر تعديل المحطة: $e');
    }
  }

  void _validateRoute(
    OperationRoute route, {
    required List<OperationRoute> existingRoutes,
  }) {
    if (route.routeCode.trim().isEmpty) {
      throw Exception('كود المسار مطلوب.');
    }
    if (route.name.trim().isEmpty) {
      throw Exception('اسم المسار مطلوب.');
    }
    if (route.startCity.trim().isEmpty || route.endCity.trim().isEmpty) {
      throw Exception('نقطتا البداية والنهاية مطلوبتان.');
    }
    if (route.stations.length < 2) {
      throw Exception('لا يمكن حفظ مسار بدون نقطتي بداية ونهاية على الأقل.');
    }
    final duplicateCode = existingRoutes.any(
      (existing) =>
          existing.id != route.id &&
          existing.routeCode.trim().toLowerCase() ==
              route.routeCode.trim().toLowerCase(),
    );
    if (duplicateCode) {
      throw Exception('كود المسار مستخدم بالفعل.');
    }
    final orders = route.stations.map((station) => station.order).toList();
    final sortedOrders = [...orders]..sort();
    for (var i = 0; i < sortedOrders.length; i++) {
      if (sortedOrders[i] != i + 1) {
        throw Exception('ترتيب المحطات غير صحيح.');
      }
    }
    if (!route.stations.any((station) => station.pickupAllowed)) {
      throw Exception('يجب تحديد محطة واحدة على الأقل تسمح بالصعود.');
    }
    if (!route.stations.any((station) => station.dropoffAllowed)) {
      throw Exception('يجب تحديد محطة واحدة على الأقل تسمح بالنزول.');
    }
    for (final station in route.stations) {
      _validateStation(station);
    }
  }

  void _validateStation(RouteStation station) {
    if (station.name.trim().isEmpty) {
      throw Exception('اسم المحطة مطلوب.');
    }
    if (station.area.trim().isEmpty) {
      throw Exception('منطقة المحطة مطلوبة.');
    }
    if (!station.pickupAllowed && !station.dropoffAllowed) {
      throw Exception('يجب أن تسمح المحطة بالصعود أو النزول على الأقل.');
    }
    final latitude = station.latitude;
    final longitude = station.longitude;
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      throw Exception('إحداثيات خط العرض غير صحيحة.');
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      throw Exception('إحداثيات خط الطول غير صحيحة.');
    }
  }
}
