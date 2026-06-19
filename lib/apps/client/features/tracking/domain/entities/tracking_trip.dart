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
    this.vehicleLatitude,
    this.vehicleLongitude,
  });

  final List<TrackingPoint> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
  final TrackingTripState tripState;
  final String? tripId;
  final double? vehicleLatitude;
  final double? vehicleLongitude;
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
