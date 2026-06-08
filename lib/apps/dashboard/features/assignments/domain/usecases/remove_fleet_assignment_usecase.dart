import '../entities/fleet_assignment.dart';
import '../repositories/fleet_assignments_repository.dart';

class RemoveFleetAssignmentUseCase {
  final FleetAssignmentsRepository _repository;

  const RemoveFleetAssignmentUseCase(this._repository);

  Future<FleetAssignment> call({
    required String assignmentId,
    required String reason,
  }) {
    return _repository.removeAssignment(
      assignmentId: assignmentId,
      reason: reason,
    );
  }
}
