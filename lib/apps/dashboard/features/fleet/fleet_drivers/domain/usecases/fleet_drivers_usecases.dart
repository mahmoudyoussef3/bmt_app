import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import '../repositories/fleet_drivers_repository.dart';

class GetFleetDriversUseCase {
  final FleetDriversRepository _repository;
  const GetFleetDriversUseCase(this._repository);
  Future<List<FleetDriver>> call() => _repository.getDrivers();
}

class CreateFleetDriverUseCase {
  final FleetDriversRepository _repository;
  const CreateFleetDriverUseCase(this._repository);
  Future<FleetDriver> call(FleetDriver driver) => _repository.createDriver(driver);
}

class UpdateFleetDriverUseCase {
  final FleetDriversRepository _repository;
  const UpdateFleetDriverUseCase(this._repository);
  Future<FleetDriver> call(FleetDriver driver) => _repository.updateDriver(driver);
}

class UpdateFleetDriverStatusUseCase {
  final FleetDriversRepository _repository;
  const UpdateFleetDriverStatusUseCase(this._repository);
  Future<FleetDriver> call(String driverId, FleetDriverStatus status) =>
      _repository.updateDriverStatus(driverId, status);
}

class UploadDriverFileUseCase {
  final FleetDriversRepository _repository;
  const UploadDriverFileUseCase(this._repository);
  Future<String> call(String bucket, String path, List<int> bytes) =>
      _repository.uploadFile(bucket, path, bytes);
}

class DeleteDriverFileUseCase {
  final FleetDriversRepository _repository;
  const DeleteDriverFileUseCase(this._repository);
  Future<void> call(String bucket, String path) =>
      _repository.deleteFile(bucket, path);
}
