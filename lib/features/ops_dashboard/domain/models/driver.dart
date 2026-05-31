class Driver {
  final String id;
  final String name;
  final String phone;
  final DriverStatus status;
  final String? vehicleId;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.status = DriverStatus.offline,
    this.vehicleId,
  });
}

enum DriverStatus { online, offline, onTrip, breakTime }
