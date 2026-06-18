import '../../domain/entities/operation_route.dart';
import '../models/operation_route_model.dart';

abstract class RoutesDatasource {
  Future<List<OperationRouteModel>> fetchRoutes();
  Future<OperationRouteModel> createRoute(OperationRoute route);
  Future<OperationRouteModel> updateRoute(OperationRoute route);
  Future<void> deleteRoute(String routeId);
  Future<OperationRouteModel> addStation(String routeId, RouteStation station);
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  );
  Future<OperationRouteModel> deleteStation(String routeId, String stationId);
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  );
}
