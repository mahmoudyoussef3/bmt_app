import '../../domain/entities/tracking_trip.dart';

class TrackingPointModel {
  const TrackingPointModel({
    required this.latitude,
    required this.longitude,
  });

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
    this.vehicleLatitude,
    this.vehicleLongitude,
  });

  final List<TrackingPointModel> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
  final TrackingTripState tripState;
  final String? tripId;
  final double? vehicleLatitude;
  final double? vehicleLongitude;

  TrackingTripData toEntity() {
    return TrackingTripData(
      routePoints: routePoints.map((p) => p.toEntity()).toList(),
      timelineSteps: timelineSteps,
      stops: stops,
      tripState: tripState,
      tripId: tripId,
      vehicleLatitude: vehicleLatitude,
      vehicleLongitude: vehicleLongitude,
    );
  }
}
