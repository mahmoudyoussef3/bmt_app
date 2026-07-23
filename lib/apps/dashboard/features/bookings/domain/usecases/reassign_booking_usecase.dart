import '../entities/operation_booking.dart';
import '../entities/reassignment_target.dart';
import '../repositories/bookings_repository.dart';

/// Trips a booking may be moved onto.
class GetReassignmentTargetsUseCase {
  const GetReassignmentTargetsUseCase(this._repository);

  final BookingsRepository _repository;

  Future<List<ReassignmentTarget>> call() =>
      _repository.getReassignmentTargets();
}

/// Moves a booking onto another trip, releasing its previous seat.
class ReassignBookingUseCase {
  const ReassignBookingUseCase(this._repository);

  final BookingsRepository _repository;

  Future<OperationBooking> call(String bookingId, String newTripId) =>
      _repository.reassignBooking(bookingId, newTripId);
}
