import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class BulkApproveBookingsUseCase {
  final BookingsRepository _repository;

  const BulkApproveBookingsUseCase(this._repository);

  Future<List<OperationBooking>> call(List<String> bookingIds, String? note) {
    return _repository.bulkApprove(bookingIds, note);
  }
}
