import '../entities/fleet_workspace.dart';

abstract class FleetRepository {
  Future<FleetWorkspace> getWorkspace();
  Future<FleetDriver> createDriver(FleetDriver driver);
  Future<FleetDriver> updateDriver(FleetDriver driver);
  Future<FleetDriver> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  );
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle);
  Future<FleetVehicle> updateVehicle(FleetVehicle vehicle);
  Future<FleetVehicle> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  );
  Future<FleetAssignment> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  );
  Future<FleetAssignment> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  );
  Future<FleetAssignment> removeAssignment(String assignmentId);
}
