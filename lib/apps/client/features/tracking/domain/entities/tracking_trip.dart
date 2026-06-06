enum TrackingTripState {
  notStarted,
  driverOnWay,
  boarding,
  inProgress,
  completed,
}

class TrackingPoint {
  const TrackingPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class TrackingTripData {
  const TrackingTripData({
    required this.routePoints,
    required this.timelineSteps,
    required this.stops,
  });

  final List<TrackingPoint> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
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
