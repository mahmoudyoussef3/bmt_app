import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

class AssignBookingsToTripUseCase {
  final BookingsRepository _repository;

  const AssignBookingsToTripUseCase(this._repository);

  Future<List<OperationBooking>> call(List<String> bookingIds, String tripId) {
    return _repository.assignToTrip(bookingIds, tripId);
  }
}
