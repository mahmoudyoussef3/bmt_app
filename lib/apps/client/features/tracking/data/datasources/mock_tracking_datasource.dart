import '../models/tracking_trip_model.dart';

class MockTrackingDatasource {
  const MockTrackingDatasource();

  Future<TrackingTripDataModel> getTrackingTrip() async {
    return const TrackingTripDataModel(
      routePoints: [
        TrackingPointModel(x: 0.15, y: 0.85),
        TrackingPointModel(x: 0.22, y: 0.72),
        TrackingPointModel(x: 0.35, y: 0.65),
        TrackingPointModel(x: 0.48, y: 0.58),
        TrackingPointModel(x: 0.55, y: 0.45),
        TrackingPointModel(x: 0.62, y: 0.38),
        TrackingPointModel(x: 0.72, y: 0.30),
        TrackingPointModel(x: 0.82, y: 0.22),
        TrackingPointModel(x: 0.90, y: 0.12),
      ],
      timelineSteps: [
        'Booking Confirmed',
        'Driver Assigned',
        'Driver Heading To Pickup',
        'Boarding Started',
        'Trip Started',
        'Trip Completed',
      ],
      stops: [
        'Banha Station',
        'Nasr City Station',
        'Heliopolis Station',
        'Smart Village',
      ],
    );
  }
}
