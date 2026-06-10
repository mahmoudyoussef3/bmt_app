import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class ApproveBookingUseCase {
  final BookingsRepository _repository;

  const ApproveBookingUseCase(this._repository);

  Future<OperationBooking> call(
    String bookingId,
    String reviewer,
    String? note,
  ) {
    return _repository.approveBooking(bookingId, reviewer, note);
  }
}
