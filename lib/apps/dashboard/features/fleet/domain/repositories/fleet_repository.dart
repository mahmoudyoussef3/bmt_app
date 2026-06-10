import '../../shared/domain/entities/fleet_workspace.dart';

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

  // Document Management & File Storage
  Future<FleetDocument> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  });
  Future<FleetDocument> updateDocument({
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
  Future<String> uploadFile(String bucket, String path, List<int> bytes);
  Future<void> deleteFile(String bucket, String path);
}
