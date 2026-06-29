import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class WatchBookingsUseCase {
  const WatchBookingsUseCase(this._repository);

  final BookingsRepository _repository;

  Stream<List<OperationBooking>> call() => _repository.watchBookings();
}
