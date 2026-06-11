import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import '../repositories/fleet_vehicles_repository.dart';

class GetFleetVehiclesUseCase {
  final FleetVehiclesRepository _repository;
  const GetFleetVehiclesUseCase(this._repository);
  Future<List<FleetVehicle>> call() => _repository.getVehicles();
}

class CreateFleetVehicleUseCase {
  final FleetVehiclesRepository _repository;
  const CreateFleetVehicleUseCase(this._repository);
  Future<FleetVehicle> call(FleetVehicle vehicle) => _repository.createVehicle(vehicle);
}

class UpdateFleetVehicleUseCase {
  final FleetVehiclesRepository _repository;
  const UpdateFleetVehicleUseCase(this._repository);
  Future<FleetVehicle> call(FleetVehicle vehicle) => _repository.updateVehicle(vehicle);
}

class UpdateFleetVehicleStatusUseCase {
  final FleetVehiclesRepository _repository;
  const UpdateFleetVehicleStatusUseCase(this._repository);
  Future<FleetVehicle> call(String vehicleId, FleetVehicleStatus status) =>
      _repository.updateVehicleStatus(vehicleId, status);
}

class UploadVehicleFileUseCase {
  final FleetVehiclesRepository _repository;
  const UploadVehicleFileUseCase(this._repository);
  Future<String> call(String bucket, String path, List<int> bytes) =>
      _repository.uploadFile(bucket, path, bytes);
}

class DeleteVehicleFileUseCase {
  final FleetVehiclesRepository _repository;
  const DeleteVehicleFileUseCase(this._repository);
  Future<void> call(String bucket, String path) =>
      _repository.deleteFile(bucket, path);
}
