enum TrackingTripState {
  notStarted,
  driverOnWay,
  boarding,
  inProgress,
  completed,
}

class TrackingPoint {
  const TrackingPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class TrackingTripData {
  const TrackingTripData({
    required this.routePoints,
    required this.timelineSteps,
    required this.stops,
    required this.tripState,
    this.tripId,
    this.bookingId,
    this.routeName,
    this.pickupName,
    this.destinationName,
    this.departureAt,
    this.arrivalAt,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehicleName,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleLatitude,
    this.vehicleLongitude,
    this.vehicleHeading,
    this.vehicleSpeed,
    this.vehicleLocationAt,
  });

  final List<TrackingPoint> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
  final TrackingTripState tripState;
  final String? tripId;
  final String? bookingId;
  final String? routeName;
  final String? pickupName;
  final String? destinationName;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehicleName;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? vehicleLatitude;
  final double? vehicleLongitude;
  final double? vehicleHeading;
  final double? vehicleSpeed;
  final DateTime? vehicleLocationAt;

  bool get hasLiveVehicleLocation =>
      vehicleLatitude != null && vehicleLongitude != null;

  String get displayDriverName =>
      driverName == null || driverName!.trim().isEmpty
      ? 'Driver assigned'
      : driverName!.trim();

  String get driverInitials {
    final parts = displayDriverName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'DR';
    return parts.map((part) => part[0]).join().toUpperCase();
  }

  String get displayVehicleName {
    final pieces = [
      vehicleName,
      vehicleType,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return pieces.isEmpty ? 'Assigned vehicle' : pieces.join(' ');
  }

  String get displayVehiclePlate =>
      vehiclePlate == null || vehiclePlate!.trim().isEmpty
      ? 'Plate pending'
      : vehiclePlate!.trim();
}

class TrackingRatings {
  const TrackingRatings({this.driver = 0, this.vehicle = 0, this.route = 0});

  final int driver;
  final int vehicle;
  final int route;

  TrackingRatings copyWith({int? driver, int? vehicle, int? route}) {
    return TrackingRatings(
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      route: route ?? this.route,
    );
  }
}
