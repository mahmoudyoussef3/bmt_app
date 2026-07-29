import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../shared/data/models/operation_trip_model.dart';
import '../../../shared/data/models/trip_pricing_model.dart';
import '../../../trip_creation/domain/entities/trip_driver_option.dart';

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

  /// Schedulable drivers, each carrying the vehicle they are assigned to. There is no
  /// matching `fetchActiveVehicles`: the planner does not choose a vehicle, so fetching
  /// the fleet to offer it was both a wasted round trip and the source of the
  /// driver/vehicle mismatches 20260731090000_driver_vehicle_authority closed.
  Future<List<TripDriverOption>> fetchActiveDrivers();

  /// One driver's current pairing, re-read at submit time. Null when the driver is not
  /// this office's.
  Future<TripDriverOption?> fetchDriverAssignment(String driverId);

  Future<List<Map<String, dynamic>>> fetchActiveRoutes();

  /// Rows (`driver_id`, `vehicle_id`, `trip_code`, `trip_date`, `departure_time`,
  /// `arrival_time`) of every non-cancelled trip whose `service_window` overlaps the
  /// given departure→arrival slot, scoped to the office. Mirrors the
  /// `operation_trips_driver_no_overlap` / `_vehicle_no_overlap` exclusion constraints
  /// exactly, so the wizard's availability pre-filter can never show a resource as free
  /// that the server would then reject.
  Future<List<Map<String, dynamic>>> fetchResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  });

  /// Route lifecycle, checked before scheduling. There is no `getDriverStatus` /
  /// `getVehicleStatus` pair any more: [fetchDriverAssignment] answers both in one
  /// round trip, and the server refuses an inactive driver or vehicle regardless.
  Future<String> getRouteStatus(String routeId);
  Stream<void> watchTripsChanges();
  Stream<void> watchTripChanges(String tripId);
}
