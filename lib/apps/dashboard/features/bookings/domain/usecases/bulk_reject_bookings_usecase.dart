import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class BulkRejectBookingsUseCase {
  final BookingsRepository _repository;

  const BulkRejectBookingsUseCase(this._repository);

  Future<List<OperationBooking>> call(List<String> bookingIds, String reason) {
    return _repository.bulkReject(bookingIds, reason);
  }
}
