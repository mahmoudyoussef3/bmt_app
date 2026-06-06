import '../entities/assigned_trip.dart';

abstract class CaptainTripRepository {
  Future<List<AssignedTrip>> getAssignedTrips();
}
