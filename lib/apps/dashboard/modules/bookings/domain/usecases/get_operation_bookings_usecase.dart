import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class GetOperationBookingsUseCase {
  final BookingsRepository _repository;

  const GetOperationBookingsUseCase(this._repository);

  Future<List<OperationBooking>> call() {
    return _repository.getBookings();
  }
}
