import '../entities/operation_booking.dart';
import '../repositories/bookings_repository.dart';

/// Records what an operator did about a booking without deciding it.
///
/// The queue's third answer, next to approve and reject: "I called them, the
/// receipt is coming." Without it the only way to leave a trace was to make a
/// decision that had not been taken.
class AddBookingNoteUseCase {
  const AddBookingNoteUseCase(this._repository);

  final BookingsRepository _repository;

  Future<OperationBooking> call(String bookingId, String note) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw Exception('لا يمكن حفظ ملاحظة فارغة.');
    }
    return _repository.addNote(bookingId, trimmed);
  }
}
