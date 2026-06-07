import '../entities/driver.dart';
import '../repositories/drivers_repository.dart';

class UpdateDriverUseCase {
  final DriversRepository _repository;

  const UpdateDriverUseCase(this._repository);

  Future<Driver> call(Driver driver) {
    return _repository.updateDriver(driver);
  }
}
