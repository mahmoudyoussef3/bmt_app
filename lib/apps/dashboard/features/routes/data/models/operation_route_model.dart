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
    required super.status,
    required super.stations,
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
      status: route.status,
      stations: route.stations,
      notes: route.notes,
    );
  }
}
