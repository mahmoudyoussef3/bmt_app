class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.licenseNumber,
    this.photoUrl,
    required this.averageRating,
    required this.totalTrips,
    required this.totalPassengers,
    this.vehicleCode,
    this.plateNumber,
    this.vehicleModel,
    this.vehicleCapacity,
  });

  final String id;
  final String name;
  final String phone;
  final String? licenseNumber;
  final String? photoUrl;
  final double averageRating;
  final int totalTrips;
  final int totalPassengers;
  final String? vehicleCode;
  final String? plateNumber;
  final String? vehicleModel;
  final int? vehicleCapacity;

  bool get hasVehicle => vehicleCode != null && vehicleCode!.isNotEmpty;
  bool get hasRating => averageRating > 0;
}
