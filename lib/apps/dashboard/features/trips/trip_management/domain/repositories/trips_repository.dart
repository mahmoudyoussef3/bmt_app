import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../../shared/domain/entities/trip_package_offer.dart';
import '../../../shared/domain/entities/trip_pricable_package.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_creation/domain/entities/trip_driver_option.dart';

abstract class TripsRepository {
  Future<List<OperationTrip>> getTrips();
  Future<OperationTrip> getTripById(String tripId);
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  });

  /// Cancels a trip, releasing its seats and cancelling its bookings and passengers.
  /// [reason] is required — the server refuses a reasonless cancellation of a trip
  /// that is already boarding or running.
  Future<OperationTrip> cancelTrip(String tripId, String reason);

  /// Closes a trip whose departure day passed while it was still open for booking,
  /// either as having operated or as cancelled.
  Future<OperationTrip> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  });
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

  /// The office's saved catalog packages — the templates the fare editor
  /// offers to add to a trip, alongside the base ticket price. Excludes
  /// single-ride-shaped packages (see [TripPricablePackage]) and packages
  /// that belong to one trip.
  Future<List<TripPricablePackage>> getOfficePricablePackages();

  /// The packages created for one trip only, so its fare editor can list
  /// them next to the catalog templates it already carries.
  Future<List<TripPricablePackage>> getTripScopedPackages(String tripId);

  /// Creates a package sold only on [tripId], returning its new id. Called
  /// by [CreateTripUseCase] and the pricing editor for any offer the
  /// operator wrote by hand instead of picking from the catalog.
  Future<String> createTripPackage({
    required String tripId,
    required TripPackageOffer offer,
  });
  Future<List<TripEvent>> getTripEvents(String tripId);

  /// Schedulable drivers with the vehicle each one operates. The planner picks a
  /// driver; the vehicle comes with them. There is deliberately no `getActiveVehicles`.
  Future<List<TripDriverOption>> getActiveDrivers();

  Future<List<Map<String, dynamic>>> getActiveRoutes();

  /// Drivers/vehicles already committed to an overlapping trip for the given
  /// departure→arrival slot. See `TripsDatasource.fetchResourceConflicts`.
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  });

  /// Emits whenever any trip's status, seats, passengers, or events change
  /// in the backend, so the trips list can refresh without a manual reload.
  Stream<void> watchTripsChanges();

  /// Emits whenever the given trip's status, seats, passengers, or events
  /// change, so an open trip details workspace can stay in sync.
  Stream<void> watchTripChanges(String tripId);
}
