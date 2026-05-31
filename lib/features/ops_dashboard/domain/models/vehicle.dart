class Vehicle {
  final String id;
  final String plateNumber;
  final String model;
  final VehicleStatus status;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.model,
    this.status = VehicleStatus.active,
  });
}

enum VehicleStatus { active, maintenance, outOfService }
