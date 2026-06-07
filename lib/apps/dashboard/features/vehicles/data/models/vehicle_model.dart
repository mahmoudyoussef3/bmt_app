import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.plateNumber,
    required super.type,
    required super.model,
    required super.capacity,
    required super.status,
    required super.currentDriver,
    required super.currentRoute,
    required super.licenseExpiry,
    required super.insuranceExpiry,
    required super.inspectionExpiry,
    required super.imageLabel,
    required super.documents,
    required super.maintenance,
    required super.trips,
    required super.previousDrivers,
    required super.notes,
  });

  factory VehicleModel.fromEntity(Vehicle vehicle) {
    return VehicleModel(
      id: vehicle.id,
      plateNumber: vehicle.plateNumber,
      type: vehicle.type,
      model: vehicle.model,
      capacity: vehicle.capacity,
      status: vehicle.status,
      currentDriver: vehicle.currentDriver,
      currentRoute: vehicle.currentRoute,
      licenseExpiry: vehicle.licenseExpiry,
      insuranceExpiry: vehicle.insuranceExpiry,
      inspectionExpiry: vehicle.inspectionExpiry,
      imageLabel: vehicle.imageLabel,
      documents: vehicle.documents,
      maintenance: vehicle.maintenance,
      trips: vehicle.trips,
      previousDrivers: vehicle.previousDrivers,
      notes: vehicle.notes,
    );
  }
}
