import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class RenewVehicleDocumentUseCase {
  final VehiclesRepository _repository;

  const RenewVehicleDocumentUseCase(this._repository);

  Future<Vehicle> call(String vehicleId, String documentTitle) {
    return _repository.renewDocument(vehicleId, documentTitle);
  }
}
