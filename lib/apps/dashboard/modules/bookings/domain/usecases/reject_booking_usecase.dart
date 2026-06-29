import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class RejectBookingUseCase {
  final BookingsRepository _repository;

  const RejectBookingUseCase(this._repository);

  Future<OperationBooking> call(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) {
    return _repository.rejectBooking(bookingId, reviewer, reason, note);
  }
}
