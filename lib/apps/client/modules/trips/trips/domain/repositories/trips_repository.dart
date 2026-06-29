import '../entities/trip.dart';

abstract class TripsRepository {
  Future<List<TripData>> getTrips();

  Future<TripData?> getTripById(String id);
}
