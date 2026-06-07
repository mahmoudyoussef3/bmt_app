import '../entities/driver.dart';
import '../repositories/drivers_repository.dart';

class CreateDriverUseCase {
  final DriversRepository _repository;

  const CreateDriverUseCase(this._repository);

  Future<Driver> call(Driver driver) {
    return _repository.createDriver(driver);
  }
}
