import '../models/seat_selection_model.dart';

abstract class SeatSelectionDatasource {
  Future<SeatSelectionModel> getSeatSelectionData(String tripId);

  /// Step 1: Reserve a seat for 5 minutes.
  /// Returns {seat_id, lock_expires_at} on success.
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  });

  /// Hands back a lock taken by [lockTripSeat] when the booking it was taken
  /// for never happened. A seat that already carries a booking is untouched.
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  });

  /// Step 2: Confirm booking after payment method is selected.
  /// Returns {booking_id, booking_number, seat_label, payment_amount}.
  Future<Map<String, dynamic>> confirmSeatBooking(Map<String, dynamic> params);

  /// Legacy single-step booking — kept for backward compatibility.
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params);

  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  );
}
