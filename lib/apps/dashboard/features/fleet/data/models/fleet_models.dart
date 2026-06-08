import '../../domain/entities/fleet_workspace.dart';

class FleetDriverModel extends FleetDriver {
  const FleetDriverModel({
    required super.id,
    required super.imageLabel,
    required super.name,
    required super.phone,
    required super.nationalId,
    required super.licenseNumber,
    required super.licenseExpiry,
    required super.status,
    super.currentVehicleId,
    required super.address,
    required super.emergencyContact,
    super.tripHistory,
    super.violations,
    super.documents,
    super.activityTimeline,
  });

  factory FleetDriverModel.fromEntity(FleetDriver driver) {
    return FleetDriverModel(
      id: driver.id,
      imageLabel: driver.imageLabel,
      name: driver.name,
      phone: driver.phone,
      nationalId: driver.nationalId,
      licenseNumber: driver.licenseNumber,
      licenseExpiry: driver.licenseExpiry,
      status: driver.status,
      currentVehicleId: driver.currentVehicleId,
      address: driver.address,
      emergencyContact: driver.emergencyContact,
      tripHistory: driver.tripHistory,
      violations: driver.violations,
      documents: driver.documents,
      activityTimeline: driver.activityTimeline,
    );
  }
}

class FleetVehicleModel extends FleetVehicle {
  const FleetVehicleModel({
    required super.id,
    required super.imageLabel,
    required super.vehicleNumber,
    required super.plateNumber,
    required super.model,
    required super.modelYear,
    required super.seatsCount,
    super.currentDriverId,
    required super.status,
    required super.licenseExpiry,
    required super.insuranceExpiry,
    required super.inspectionExpiry,
    super.images,
    super.previousDrivers,
    super.tripHistory,
    super.timeline,
  });

  factory FleetVehicleModel.fromEntity(FleetVehicle vehicle) {
    return FleetVehicleModel(
      id: vehicle.id,
      imageLabel: vehicle.imageLabel,
      vehicleNumber: vehicle.vehicleNumber,
      plateNumber: vehicle.plateNumber,
      model: vehicle.model,
      modelYear: vehicle.modelYear,
      seatsCount: vehicle.seatsCount,
      currentDriverId: vehicle.currentDriverId,
      status: vehicle.status,
      licenseExpiry: vehicle.licenseExpiry,
      insuranceExpiry: vehicle.insuranceExpiry,
      inspectionExpiry: vehicle.inspectionExpiry,
      images: vehicle.images,
      previousDrivers: vehicle.previousDrivers,
      tripHistory: vehicle.tripHistory,
      timeline: vehicle.timeline,
    );
  }
}

class FleetAssignmentModel extends FleetAssignment {
  const FleetAssignmentModel({
    required super.id,
    required super.driverId,
    required super.vehicleId,
    required super.assignedAt,
    required super.status,
    super.history,
  });

  factory FleetAssignmentModel.fromEntity(FleetAssignment assignment) {
    return FleetAssignmentModel(
      id: assignment.id,
      driverId: assignment.driverId,
      vehicleId: assignment.vehicleId,
      assignedAt: assignment.assignedAt,
      status: assignment.status,
      history: assignment.history,
    );
  }
}
