import '../entities/driver.dart';
import '../repositories/drivers_repository.dart';

class GetDriversUseCase {
  final DriversRepository _repository;

  const GetDriversUseCase(this._repository);

  Future<List<Driver>> call() {
    return _repository.getDrivers();
  }
}
