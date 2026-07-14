import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

/// Cancels a booking whose payment the dashboard has not approved yet, freeing
/// the seat for other passengers.
class CancelBookingUseCase {
  const CancelBookingUseCase(this._repository);

  final TripsRepository _repository;

  Future<void> call(TripData trip, String reason) {
    if (!trip.canBeCancelled) {
      throw Exception(
        'This booking is already paid and confirmed, so it can no longer be '
        'cancelled from the app. Please contact support.',
      );
    }
    return _repository.cancelBooking(trip.id, reason);
  }
}
