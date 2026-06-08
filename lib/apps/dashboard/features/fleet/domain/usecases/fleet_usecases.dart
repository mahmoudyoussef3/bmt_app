import '../entities/fleet_workspace.dart';
import '../repositories/fleet_repository.dart';

class GetFleetWorkspaceUseCase {
  final FleetRepository _repository;

  const GetFleetWorkspaceUseCase(this._repository);

  Future<FleetWorkspace> call() => _repository.getWorkspace();
}

class CreateFleetDriverUseCase {
  final FleetRepository _repository;

  const CreateFleetDriverUseCase(this._repository);

  Future<FleetDriver> call(FleetDriver driver) {
    return _repository.createDriver(driver);
  }
}

class UpdateFleetDriverUseCase {
  final FleetRepository _repository;

  const UpdateFleetDriverUseCase(this._repository);

  Future<FleetDriver> call(FleetDriver driver) {
    return _repository.updateDriver(driver);
  }
}

class UpdateFleetDriverStatusUseCase {
  final FleetRepository _repository;

  const UpdateFleetDriverStatusUseCase(this._repository);

  Future<FleetDriver> call(String driverId, FleetDriverStatus status) {
    return _repository.updateDriverStatus(driverId, status);
  }
}

class CreateFleetVehicleUseCase {
  final FleetRepository _repository;

  const CreateFleetVehicleUseCase(this._repository);

  Future<FleetVehicle> call(FleetVehicle vehicle) {
    return _repository.createVehicle(vehicle);
  }
}

class UpdateFleetVehicleUseCase {
  final FleetRepository _repository;

  const UpdateFleetVehicleUseCase(this._repository);

  Future<FleetVehicle> call(FleetVehicle vehicle) {
    return _repository.updateVehicle(vehicle);
  }
}

class UpdateFleetVehicleStatusUseCase {
  final FleetRepository _repository;

  const UpdateFleetVehicleStatusUseCase(this._repository);

  Future<FleetVehicle> call(String vehicleId, FleetVehicleStatus status) {
    return _repository.updateVehicleStatus(vehicleId, status);
  }
}

class AssignFleetVehicleUseCase {
  final FleetRepository _repository;

  const AssignFleetVehicleUseCase(this._repository);

  Future<FleetAssignment> call(String driverId, String vehicleId) {
    return _repository.assignDriverToVehicle(driverId, vehicleId);
  }
}

class ReassignFleetVehicleUseCase {
  final FleetRepository _repository;

  const ReassignFleetVehicleUseCase(this._repository);

  Future<FleetAssignment> call(String assignmentId, String newVehicleId) {
    return _repository.reassignVehicle(assignmentId, newVehicleId);
  }
}

class RemoveUnifiedFleetAssignmentUseCase {
  final FleetRepository _repository;

  const RemoveUnifiedFleetAssignmentUseCase(this._repository);

  Future<FleetAssignment> call(String assignmentId) {
    return _repository.removeAssignment(assignmentId);
  }
}
