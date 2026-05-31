class DriverProfile {
  final String id;
  String name;
  String phone;
  String licenseNumber;
  DateTime licenseExpiry;
  String? vehicleId;

  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.vehicleId,
  });
}
