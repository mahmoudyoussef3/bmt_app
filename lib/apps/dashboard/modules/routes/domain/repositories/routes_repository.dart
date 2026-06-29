import '../entities/operation_route.dart';

abstract class RoutesRepository {
  Future<List<OperationRoute>> getRoutes();
  Future<OperationRoute> createRoute(OperationRoute route);
  Future<OperationRoute> updateRoute(OperationRoute route);
  Future<void> deleteRoute(String routeId);
  Future<OperationRoute> addStation(String routeId, RouteStation station);
  Future<OperationRoute> updateStation(String routeId, RouteStation station);
  Future<OperationRoute> deleteStation(String routeId, String stationId);
  Future<OperationRoute> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  );
}
