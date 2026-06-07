import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class GetVehiclesUseCase {
  final VehiclesRepository _repository;

  const GetVehiclesUseCase(this._repository);

  Future<List<Vehicle>> call() {
    return _repository.getVehicles();
  }
}
