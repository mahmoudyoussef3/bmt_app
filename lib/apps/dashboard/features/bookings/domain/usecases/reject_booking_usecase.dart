import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class RejectBookingUseCase {
  final BookingsRepository _repository;

  const RejectBookingUseCase(this._repository);

  Future<OperationBooking> call(String bookingId, String reason) {
    return _repository.rejectBooking(bookingId, reason);
  }
}
