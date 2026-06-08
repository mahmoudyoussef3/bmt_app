import '../entities/fleet_assignment.dart';

abstract class FleetAssignmentsRepository {
  Future<FleetAssignmentsData> getAssignmentsData();

  Future<FleetAssignment> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  });

  Future<FleetAssignment> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  });

  Future<FleetAssignment> removeAssignment({
    required String assignmentId,
    required String reason,
  });
}
