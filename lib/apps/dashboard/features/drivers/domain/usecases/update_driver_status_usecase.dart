import '../entities/driver.dart';
import '../repositories/drivers_repository.dart';

class UpdateDriverStatusUseCase {
  final DriversRepository _repository;

  const UpdateDriverStatusUseCase(this._repository);

  Future<Driver> call(String driverId, DriverStatus status) {
    return _repository.updateDriverStatus(driverId, status);
  }
}
