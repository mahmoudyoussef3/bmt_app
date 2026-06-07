import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class UpdateBookingStatusUseCase {
  final BookingsRepository _repository;

  const UpdateBookingStatusUseCase(this._repository);

  Future<OperationBooking> call(String bookingId, BookingStatus status) {
    return _repository.updateBookingStatus(bookingId, status);
  }
}
