import '../repositories/seat_selection_repository.dart';

class ConfirmSeatBookingUseCase {
  final SeatSelectionRepository _repository;

  const ConfirmSeatBookingUseCase(this._repository);

  /// Confirms a booking after the seat lock is held and payment details collected.
  /// Returns {booking_id, booking_number, seat_label, payment_amount}.
  /// Throws 'lock_expired' if the 5-minute hold timed out.
  /// Throws 'seat_unavailable' if the lock no longer belongs to this user.
  Future<Map<String, dynamic>> call(Map<String, dynamic> params) {
    return _repository.confirmSeatBooking(params);
  }
}
