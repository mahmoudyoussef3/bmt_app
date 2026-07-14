import '../entities/seat_option.dart';

abstract class SeatSelectionRepository {
  Future<SeatSelectionData> getSeatSelectionData(String tripId);

  /// Step 1 of two-step booking: reserves seat for 5 minutes.
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  });

  /// Releases a lock taken by [lockTripSeat] when the booking never happened.
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  });

  /// Step 2: confirms booking after payment details are collected.
  Future<Map<String, dynamic>> confirmSeatBooking(Map<String, dynamic> params);

  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params);

  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  );
}
