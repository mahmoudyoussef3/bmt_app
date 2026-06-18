import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_assignment.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import '../repositories/fleet_assignments_repository.dart';

class GetFleetAssignmentsUseCase {
  final FleetAssignmentsRepository _repository;
  const GetFleetAssignmentsUseCase(this._repository);
  Future<List<FleetAssignment>> call() => _repository.getAssignments();
}

class GetAssignmentDriversUseCase {
  final FleetAssignmentsRepository _repository;
  const GetAssignmentDriversUseCase(this._repository);
  Future<List<FleetDriver>> call() => _repository.getDrivers();
}

class GetAssignmentVehiclesUseCase {
  final FleetAssignmentsRepository _repository;
  const GetAssignmentVehiclesUseCase(this._repository);
  Future<List<FleetVehicle>> call() => _repository.getVehicles();
}

class AssignFleetVehicleUseCase {
  final FleetAssignmentsRepository _repository;
  const AssignFleetVehicleUseCase(this._repository);
  Future<FleetAssignment> call(String driverId, String vehicleId) =>
      _repository.assignDriverToVehicle(driverId, vehicleId);
}

class ReassignFleetVehicleUseCase {
  final FleetAssignmentsRepository _repository;
  const ReassignFleetVehicleUseCase(this._repository);
  Future<FleetAssignment> call(String assignmentId, String newVehicleId) =>
      _repository.reassignVehicle(assignmentId, newVehicleId);
}

class RemoveFleetAssignmentUseCase {
  final FleetAssignmentsRepository _repository;
  const RemoveFleetAssignmentUseCase(this._repository);
  Future<FleetAssignment> call(String assignmentId) =>
      _repository.removeAssignment(assignmentId);
}

class DeleteFleetAssignmentUseCase {
  final FleetAssignmentsRepository _repository;
  const DeleteFleetAssignmentUseCase(this._repository);
  Future<void> call(String assignmentId) =>
      _repository.deleteAssignment(assignmentId);
}
