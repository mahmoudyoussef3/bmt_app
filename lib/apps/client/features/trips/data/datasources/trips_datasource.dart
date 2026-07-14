import '../models/trip_model.dart';

abstract class TripsDatasource {
  Future<List<TripModel>> getTrips();
  Future<TripModel?> getTripById(String id);
  Future<void> cancelBooking(String bookingId, String reason);
  Stream<void> watchTripChanges();
}
