import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class UpdateVehicleStatusUseCase {
  final VehiclesRepository _repository;

  const UpdateVehicleStatusUseCase(this._repository);

  Future<Vehicle> call(String vehicleId, VehicleStatus status) {
    return _repository.updateVehicleStatus(vehicleId, status);
  }
}
