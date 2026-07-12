import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';

abstract class TripsRepository {
  Future<List<OperationTrip>> getTrips();
  Future<OperationTrip> getTripById(String tripId);
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
  Future<void> deleteTrip(String tripId);
  Future<OperationTrip> updatePassenger(String tripId, TripPassenger passenger);
  Future<OperationTrip> cancelPassenger(String tripId, String passengerId);
  Future<OperationTrip> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  );
  Future<List<TripPricing>> getTripPricing(String tripId);
  Future<TripPricing> upsertTripPricing(TripPricing pricing);
  Future<TripPricing> toggleTripPricingStatus(String pricingId, bool isActive);
  Future<List<TripEvent>> getTripEvents(String tripId);
  Future<List<Map<String, dynamic>>> getActiveDrivers();
  Future<List<Map<String, dynamic>>> getActiveVehicles();
  Future<List<Map<String, dynamic>>> getActiveRoutes();

  /// Emits whenever any trip's status, seats, passengers, or events change
  /// in the backend, so the trips list can refresh without a manual reload.
  Stream<void> watchTripsChanges();

  /// Emits whenever the given trip's status, seats, passengers, or events
  /// change, so an open trip details workspace can stay in sync.
  Stream<void> watchTripChanges(String tripId);
}
