import '../../domain/entities/operation_route.dart';

class OperationRouteModel extends OperationRoute {
  const OperationRouteModel({
    required super.id,
    required super.name,
    required super.startCity,
    required super.endCity,
    required super.duration,
    required super.distance,
    required super.tripsCount,
    required super.activePackagesCount,
    required super.status,
    required super.stations,
    required super.activeTrips,
    required super.packages,
    required super.statistics,
    required super.notes,
  });

  factory OperationRouteModel.fromEntity(OperationRoute route) {
    return OperationRouteModel(
      id: route.id,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      tripsCount: route.tripsCount,
      activePackagesCount: route.activePackagesCount,
      status: route.status,
      stations: route.stations,
      activeTrips: route.activeTrips,
      packages: route.packages,
      statistics: route.statistics,
      notes: route.notes,
    );
  }
}
