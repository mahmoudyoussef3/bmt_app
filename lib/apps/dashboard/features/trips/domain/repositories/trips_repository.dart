import '../entities/operation_trip.dart';

abstract class TripsRepository {
  Future<List<OperationTrip>> getTrips();
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  );
  Future<OperationTrip> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  );
  Future<OperationTrip> createTrip(CreateTripInput input);
  Future<OperationTrip> updateTripInfo(OperationTrip trip);
  Future<OperationTrip> updatePassenger(String tripId, TripPassenger passenger);
  Future<OperationTrip> cancelPassenger(String tripId, String passengerId);
  Future<OperationTrip> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  );
}
