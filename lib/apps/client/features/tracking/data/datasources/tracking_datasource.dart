import '../../domain/entities/tracking_trip.dart';

abstract class TrackingDatasource {
  /// The rider's trackable trip, or [TrackingTripData.none] when they have no
  /// confirmed booking to track.
  Future<TrackingTripData> getTrackingTrip({String? bookingId, String? tripId});

  /// Live GPS fixes as the captain's device reports them.
  Stream<TrackingPoint> watchVehiclePosition(String tripId);

  /// Fires whenever any table backing the trip changes, so the screen can
  /// refetch its joined view.
  Stream<void> watchTripChanges(String tripId);
}
