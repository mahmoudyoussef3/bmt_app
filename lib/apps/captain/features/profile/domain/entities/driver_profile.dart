/// A driver's account standing, mirroring `drivers.status`. A captain who
/// isn't active couldn't have signed in in the first place (the phone-login
/// RPC only matches active drivers) — this is shown as confirmation, not a
/// gate the UI enforces itself.
enum DriverAccountStatus { active, suspended, archived }

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
    this.employeeCode,
    this.licenseExpiryDate,
    this.hireDate,
    this.accountStatus = DriverAccountStatus.active,
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
  final String? employeeCode;
  final DateTime? licenseExpiryDate;
  final DateTime? hireDate;
  final DriverAccountStatus accountStatus;

  bool get hasVehicle => vehicleCode != null && vehicleCode!.isNotEmpty;
  bool get hasRating => averageRating > 0;

  bool get isLicenseExpired =>
      licenseExpiryDate != null && licenseExpiryDate!.isBefore(DateTime.now());

  bool get isLicenseExpiringSoon =>
      licenseExpiryDate != null &&
      !isLicenseExpired &&
      licenseExpiryDate!.difference(DateTime.now()).inDays <= 30;
}
