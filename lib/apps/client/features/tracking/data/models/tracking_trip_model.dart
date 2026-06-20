import '../../domain/entities/tracking_trip.dart';

class TrackingPointModel {
  const TrackingPointModel({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  TrackingPoint toEntity() =>
      TrackingPoint(latitude: latitude, longitude: longitude);
}

class TrackingTripDataModel {
  const TrackingTripDataModel({
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

  final List<TrackingPointModel> routePoints;
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

  TrackingTripData toEntity() {
    return TrackingTripData(
      routePoints: routePoints.map((p) => p.toEntity()).toList(),
      timelineSteps: timelineSteps,
      stops: stops,
      tripState: tripState,
      tripId: tripId,
      bookingId: bookingId,
      routeName: routeName,
      pickupName: pickupName,
      destinationName: destinationName,
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      vehicleLatitude: vehicleLatitude,
      vehicleLongitude: vehicleLongitude,
      vehicleHeading: vehicleHeading,
      vehicleSpeed: vehicleSpeed,
      vehicleLocationAt: vehicleLocationAt,
    );
  }
}
