import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Repository contract for fleet vehicle operations.
abstract class FleetVehiclesRepository {
  Future<List<FleetVehicle>> getVehicles();
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle);
  Future<FleetVehicle> updateVehicle(FleetVehicle vehicle);
  Future<FleetVehicle> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  );
  Future<void> deleteVehicle(String vehicleId);
  Future<String> uploadFile(String bucket, String path, List<int> bytes);
  Future<void> deleteFile(String bucket, String path);
}
