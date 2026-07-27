import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../shared/data/models/operation_trip_model.dart';
import '../../../shared/data/models/trip_pricing_model.dart';

abstract class TripsDatasource {
  Future<List<OperationTripModel>> fetchTrips();
  Future<OperationTripModel> fetchTripById(String tripId);
  Future<OperationTripModel> createTrip(CreateTripInput input);
  Future<OperationTripModel> updateTripInfo(OperationTrip trip);
  Future<void> deleteTrip(String tripId);
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  });

  /// Cancellation goes through its own RPC because it always carries a reason and
  /// always means the same thing, rather than being reached through a generic status
  /// setter.
  Future<OperationTripModel> cancelTrip(String tripId, String reason);

  /// Closes a trip whose departure day passed while it was still open for booking.
  Future<OperationTripModel> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  });
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  );
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  );
  Future<OperationTripModel> cancelPassenger(String tripId, String passengerId);
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  );
  Future<List<TripPricingModel>> fetchTripPricing(String tripId);
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing);
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  );
  Future<List<TripEventModel>> fetchTripEvents(String tripId);
  Future<List<Map<String, dynamic>>> fetchActiveDrivers();
  Future<List<Map<String, dynamic>>> fetchActiveVehicles();
  Future<List<Map<String, dynamic>>> fetchActiveRoutes();
  Future<bool> checkDuplicateTrip(
    String vehicleId,
    String date,
    String departureTime,
  );
  Future<bool> checkDriverTripConflict(
    String driverId,
    String date,
    String departureTime,
  );
  Future<String> getDriverStatus(String driverId);
  Future<String> getVehicleStatus(String vehicleId);
  Future<String> getRouteStatus(String routeId);
  Stream<void> watchTripsChanges();
  Stream<void> watchTripChanges(String tripId);
}
