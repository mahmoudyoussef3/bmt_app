import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_assignment.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';

/// Repository contract for fleet assignment operations.
abstract class FleetAssignmentsRepository {
  Future<List<FleetAssignment>> getAssignments();
  Future<List<FleetDriver>> getDrivers();
  Future<List<FleetVehicle>> getVehicles();
  Future<FleetAssignment> assignDriverToVehicle(String driverId, String vehicleId);
  Future<FleetAssignment> reassignVehicle(String assignmentId, String newVehicleId);
  Future<FleetAssignment> removeAssignment(String assignmentId);
}
