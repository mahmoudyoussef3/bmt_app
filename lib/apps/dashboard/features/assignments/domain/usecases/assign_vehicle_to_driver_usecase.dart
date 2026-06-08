import '../entities/fleet_assignment.dart';
import '../repositories/fleet_assignments_repository.dart';

class AssignVehicleToDriverUseCase {
  final FleetAssignmentsRepository _repository;

  const AssignVehicleToDriverUseCase(this._repository);

  Future<FleetAssignment> call({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  }) {
    return _repository.assignVehicleToDriver(
      driverId: driverId,
      vehicleId: vehicleId,
      route: route,
      reason: reason,
    );
  }
}
