import '../entities/live_trip.dart';

abstract class LiveTripsRepository {
  Future<List<LiveTrip>> getLiveTrips();
}
