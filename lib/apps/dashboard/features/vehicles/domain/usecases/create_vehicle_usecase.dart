import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class CreateVehicleUseCase {
  final VehiclesRepository _repository;

  const CreateVehicleUseCase(this._repository);

  Future<Vehicle> call(Vehicle vehicle) {
    return _repository.createVehicle(vehicle);
  }
}
