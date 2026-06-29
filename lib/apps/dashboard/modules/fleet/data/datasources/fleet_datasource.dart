import '../../shared/domain/entities/fleet_workspace.dart';
import '../models/fleet_models.dart';

abstract class FleetDatasource {
  Future<FleetWorkspace> fetchWorkspace();
  Future<FleetDriverModel> createDriver(FleetDriver driver);
  Future<FleetDriverModel> updateDriver(FleetDriver driver);
  Future<FleetDriverModel> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  );
  Future<void> deleteDriver(String driverId);
  Future<FleetVehicleModel> createVehicle(FleetVehicle vehicle);
  Future<FleetVehicleModel> updateVehicle(FleetVehicle vehicle);
  Future<FleetVehicleModel> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  );
  Future<void> deleteVehicle(String vehicleId);
  Future<FleetAssignmentModel> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  );
  Future<FleetAssignmentModel> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  );
  Future<FleetAssignmentModel> removeAssignment(String assignmentId);
  Future<void> deleteAssignment(String assignmentId);

  Future<FleetDocumentModel> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  });
  Future<FleetDocumentModel> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  });
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  });
}
