import '../entities/trip.dart';

abstract class TripsRepository {
  Future<List<TripData>> getTrips();

  Future<TripData?> getTripById(String id);

  /// Cancels an unapproved booking and releases its seat.
  Future<void> cancelBooking(String bookingId, String reason);

  Stream<void> watchTripChanges();
}
