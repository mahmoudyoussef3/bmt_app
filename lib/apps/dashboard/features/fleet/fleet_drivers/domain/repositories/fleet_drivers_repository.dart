import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Repository contract for fleet driver operations.
abstract class FleetDriversRepository {
  Future<List<FleetDriver>> getDrivers();
  Future<FleetDriver> createDriver(FleetDriver driver);
  Future<FleetDriver> updateDriver(FleetDriver driver);
  Future<FleetDriver> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  );
  Future<void> deleteDriver(String driverId);
  Future<String> uploadFile(String bucket, String path, List<int> bytes);
  Future<void> deleteFile(String bucket, String path);
}
