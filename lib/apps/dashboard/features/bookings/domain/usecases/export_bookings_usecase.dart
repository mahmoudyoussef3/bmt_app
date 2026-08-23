import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

/// Exports the operator's current view of the bookings queue to a CSV file.
class ExportBookingsUseCase {
  const ExportBookingsUseCase(this._repository);

  final BookingsRepository _repository;

  Future<String> call(List<OperationBooking> bookings) =>
      _repository.exportBookingsCsv(bookings);
}
