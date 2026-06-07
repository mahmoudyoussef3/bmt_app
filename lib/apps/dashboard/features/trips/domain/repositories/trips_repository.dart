import '../entities/operation_trip.dart';

abstract class TripsRepository {
  Future<List<OperationTrip>> getTrips();
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  );
}
