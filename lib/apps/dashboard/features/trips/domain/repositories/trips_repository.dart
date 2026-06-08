import '../entities/operation_trip.dart';
import '../entities/trip_pricing.dart';

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
  Future<List<TripPricing>> getTripPricing(String tripId);
  Future<TripPricing> upsertTripPricing(TripPricing pricing);
  Future<TripPricing> toggleTripPricingStatus(String pricingId, bool isActive);
}
