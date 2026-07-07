import 'package:bmt_app/core/tracking/progress/route_stop.dart';

enum TrackingTripState {
  notStarted,
  driverOnWay,
  boarding,
  inProgress,
  completed,
}

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.heading,
    this.speed,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime? recordedAt;

  /// Degrees clockwise from north; negative means the device had no heading.
  final double? heading;

  /// Ground speed in m/s as reported by the captain device.
  final double? speed;

  /// Horizontal GPS accuracy radius in meters.
  final double? accuracy;
}

class TrackingTripData {
  const TrackingTripData({
    required this.routePoints,
    required this.timelineSteps,
    required this.stops,
    required this.tripState,
    this.routeStops = const [],
    this.passengerPickupName,
    this.passengerDropoffName,
    this.passengerStatus,
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
    this.vehicleAccuracy,
    this.vehicleLocationAt,
  });

  final List<TrackingPoint> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
  final TrackingTripState tripState;

  /// Ordered route stops with coordinates and planned times, ready for the
  /// route progress engine.
  final List<RouteStop> routeStops;

  /// The rider's own manifest row: where they board/alight and whether the
  /// captain confirmed them on board.
  final String? passengerPickupName;
  final String? passengerDropoffName;
  final String? passengerStatus;
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

  /// Ground speed in m/s (Geolocator convention); see [vehicleSpeedKmh].
  final double? vehicleSpeed;
  final double? vehicleAccuracy;
  final DateTime? vehicleLocationAt;

  bool get hasLiveVehicleLocation =>
      vehicleLatitude != null && vehicleLongitude != null;

  /// The captain marks passengers `confirmed` when they board.
  bool get passengerBoarded => passengerStatus == 'confirmed';

  double? get vehicleSpeedKmh =>
      vehicleSpeed == null || vehicleSpeed! < 0 ? null : vehicleSpeed! * 3.6;

  TrackingPoint? get vehicleFix => hasLiveVehicleLocation
      ? TrackingPoint(
          latitude: vehicleLatitude!,
          longitude: vehicleLongitude!,
          recordedAt: vehicleLocationAt,
          heading: vehicleHeading,
          speed: vehicleSpeed,
          accuracy: vehicleAccuracy,
        )
      : null;

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

  TrackingTripData copyWith({
    List<TrackingPoint>? routePoints,
    List<String>? timelineSteps,
    List<String>? stops,
    TrackingTripState? tripState,
    List<RouteStop>? routeStops,
    String? passengerPickupName,
    String? passengerDropoffName,
    String? passengerStatus,
    String? tripId,
    String? bookingId,
    String? routeName,
    String? pickupName,
    String? destinationName,
    DateTime? departureAt,
    DateTime? arrivalAt,
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? vehicleName,
    String? vehicleType,
    String? vehiclePlate,
    double? vehicleLatitude,
    double? vehicleLongitude,
    double? vehicleHeading,
    double? vehicleSpeed,
    double? vehicleAccuracy,
    DateTime? vehicleLocationAt,
  }) {
    return TrackingTripData(
      routePoints: routePoints ?? this.routePoints,
      timelineSteps: timelineSteps ?? this.timelineSteps,
      stops: stops ?? this.stops,
      tripState: tripState ?? this.tripState,
      routeStops: routeStops ?? this.routeStops,
      passengerPickupName: passengerPickupName ?? this.passengerPickupName,
      passengerDropoffName: passengerDropoffName ?? this.passengerDropoffName,
      passengerStatus: passengerStatus ?? this.passengerStatus,
      tripId: tripId ?? this.tripId,
      bookingId: bookingId ?? this.bookingId,
      routeName: routeName ?? this.routeName,
      pickupName: pickupName ?? this.pickupName,
      destinationName: destinationName ?? this.destinationName,
      departureAt: departureAt ?? this.departureAt,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleLatitude: vehicleLatitude ?? this.vehicleLatitude,
      vehicleLongitude: vehicleLongitude ?? this.vehicleLongitude,
      vehicleHeading: vehicleHeading ?? this.vehicleHeading,
      vehicleSpeed: vehicleSpeed ?? this.vehicleSpeed,
      vehicleAccuracy: vehicleAccuracy ?? this.vehicleAccuracy,
      vehicleLocationAt: vehicleLocationAt ?? this.vehicleLocationAt,
    );
  }
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
