import '../../domain/entities/driver.dart';

class DriverModel extends Driver {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.nationalId,
    required super.email,
    required super.address,
    required super.avatarInitials,
    required super.currentVehicle,
    required super.currentRoute,
    required super.totalTrips,
    required super.todayTrips,
    required super.monthlyTrips,
    required super.totalPassengers,
    required super.rating,
    required super.status,
    required super.assignedAt,
    required super.licenseNumber,
    required super.licenseExpiry,
    required super.documents,
    required super.reviews,
    required super.complaints,
    required super.notes,
  });

  factory DriverModel.fromEntity(Driver driver) {
    return DriverModel(
      id: driver.id,
      name: driver.name,
      phone: driver.phone,
      nationalId: driver.nationalId,
      email: driver.email,
      address: driver.address,
      avatarInitials: driver.avatarInitials,
      currentVehicle: driver.currentVehicle,
      currentRoute: driver.currentRoute,
      totalTrips: driver.totalTrips,
      todayTrips: driver.todayTrips,
      monthlyTrips: driver.monthlyTrips,
      totalPassengers: driver.totalPassengers,
      rating: driver.rating,
      status: driver.status,
      assignedAt: driver.assignedAt,
      licenseNumber: driver.licenseNumber,
      licenseExpiry: driver.licenseExpiry,
      documents: driver.documents,
      reviews: driver.reviews,
      complaints: driver.complaints,
      notes: driver.notes,
    );
  }
}
