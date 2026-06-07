import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class UpdateVehicleUseCase {
  final VehiclesRepository _repository;

  const UpdateVehicleUseCase(this._repository);

  Future<Vehicle> call(Vehicle vehicle) {
    return _repository.updateVehicle(vehicle);
  }
}
