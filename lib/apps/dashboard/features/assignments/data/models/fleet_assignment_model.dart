import '../../domain/entities/fleet_assignment.dart';

class FleetAssignmentModel extends FleetAssignment {
  const FleetAssignmentModel({
    required super.id,
    required super.driverId,
    required super.driverName,
    required super.vehicleId,
    required super.vehiclePlate,
    required super.route,
    required super.startedAt,
    super.endedAt,
    required super.status,
    required super.reason,
    required super.timeline,
  });

  factory FleetAssignmentModel.fromEntity(FleetAssignment assignment) {
    return FleetAssignmentModel(
      id: assignment.id,
      driverId: assignment.driverId,
      driverName: assignment.driverName,
      vehicleId: assignment.vehicleId,
      vehiclePlate: assignment.vehiclePlate,
      route: assignment.route,
      startedAt: assignment.startedAt,
      endedAt: assignment.endedAt,
      status: assignment.status,
      reason: assignment.reason,
      timeline: assignment.timeline,
    );
  }
}
