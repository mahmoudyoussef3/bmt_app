import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class BulkUpdateBookingsStatusUseCase {
  final BookingsRepository _repository;

  const BulkUpdateBookingsStatusUseCase(this._repository);

  Future<List<OperationBooking>> call(
    List<String> bookingIds,
    BookingStatus status,
  ) {
    return _repository.bulkUpdateStatus(bookingIds, status);
  }
}
