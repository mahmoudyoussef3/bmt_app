import '../entities/fleet_assignment.dart';
import '../repositories/fleet_assignments_repository.dart';

class GetFleetAssignmentsUseCase {
  final FleetAssignmentsRepository _repository;

  const GetFleetAssignmentsUseCase(this._repository);

  Future<FleetAssignmentsData> call() {
    return _repository.getAssignmentsData();
  }
}
