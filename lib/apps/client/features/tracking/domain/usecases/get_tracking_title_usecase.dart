import '../entities/tracking_trip.dart';

class GetTrackingTitleUseCase {
  const GetTrackingTitleUseCase();

  String call(TrackingTripState state) {
    return switch (state) {
      TrackingTripState.notStarted => 'Trip Status',
      TrackingTripState.driverOnWay => 'Driver on the Way',
      TrackingTripState.boarding => 'Boarding Started',
      TrackingTripState.inProgress => 'Trip in Progress',
      TrackingTripState.completed => 'Trip Completed',
    };
  }
}
