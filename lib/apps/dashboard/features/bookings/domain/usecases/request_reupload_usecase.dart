import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class RequestReuploadUseCase {
  final BookingsRepository _repository;

  const RequestReuploadUseCase(this._repository);

  Future<OperationBooking> call(String bookingId, String reason) {
    return _repository.requestReupload(bookingId, reason);
  }
}
