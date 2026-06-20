import '../entities/tracking_trip.dart';

abstract class TrackingRepository {
  Future<TrackingTripData> getTrackingTrip({String? bookingId, String? tripId});
}
