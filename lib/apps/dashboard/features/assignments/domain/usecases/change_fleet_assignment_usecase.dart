import '../entities/fleet_assignment.dart';
import '../repositories/fleet_assignments_repository.dart';

class ChangeFleetAssignmentUseCase {
  final FleetAssignmentsRepository _repository;

  const ChangeFleetAssignmentUseCase(this._repository);

  Future<FleetAssignment> call({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  }) {
    return _repository.changeAssignment(
      assignmentId: assignmentId,
      vehicleId: vehicleId,
      route: route,
      reason: reason,
    );
  }
}
