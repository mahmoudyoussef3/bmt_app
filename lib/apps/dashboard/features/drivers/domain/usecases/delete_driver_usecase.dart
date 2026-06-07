import '../repositories/drivers_repository.dart';

class DeleteDriverUseCase {
  final DriversRepository _repository;

  const DeleteDriverUseCase(this._repository);

  Future<void> call(String driverId) {
    return _repository.deleteDriver(driverId);
  }
}
