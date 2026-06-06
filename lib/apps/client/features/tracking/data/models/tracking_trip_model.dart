import '../../domain/entities/tracking_trip.dart';

class TrackingPointModel {
  const TrackingPointModel({required this.x, required this.y});

  final double x;
  final double y;

  TrackingPoint toEntity() => TrackingPoint(x: x, y: y);
}

class TrackingTripDataModel {
  const TrackingTripDataModel({
    required this.routePoints,
    required this.timelineSteps,
    required this.stops,
  });

  final List<TrackingPointModel> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;

  TrackingTripData toEntity() {
    return TrackingTripData(
      routePoints: routePoints.map((point) => point.toEntity()).toList(),
      timelineSteps: timelineSteps,
      stops: stops,
    );
  }
}
