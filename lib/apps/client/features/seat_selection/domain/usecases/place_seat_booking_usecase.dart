import 'confirm_seat_booking_usecase.dart';
import 'lock_trip_seat_usecase.dart';
import 'release_trip_seat_lock_usecase.dart';

/// Books a seat as one unit of work: lock, then confirm.
///
/// The lock lives in its own transaction, so a confirm that throws would leave
/// the seat reserved-but-unbooked until the hold expires. Handing the lock back
/// here means no caller can forget to. Once the booking row exists the release
/// RPC no-ops, so a seat that was actually booked keeps its hold.
class PlaceSeatBookingUseCase {
  const PlaceSeatBookingUseCase({
    required LockTripSeatUseCase lockTripSeat,
    required ConfirmSeatBookingUseCase confirmSeatBooking,
    required ReleaseTripSeatLockUseCase releaseTripSeatLock,
  }) : _lockTripSeat = lockTripSeat,
       _confirmSeatBooking = confirmSeatBooking,
       _releaseTripSeatLock = releaseTripSeatLock;

  final LockTripSeatUseCase _lockTripSeat;
  final ConfirmSeatBookingUseCase _confirmSeatBooking;
  final ReleaseTripSeatLockUseCase _releaseTripSeatLock;

  /// Returns the confirmed booking row: {booking_id, booking_number, …}.
  Future<Map<String, dynamic>> call({
    required String tripId,
    required String seatId,
    required Map<String, dynamic> params,
  }) async {
    await _lockTripSeat(tripId: tripId, seatId: seatId);

    try {
      return await _confirmSeatBooking(params);
    } catch (_) {
      await _releaseTripSeatLock(tripId: tripId, seatId: seatId);
      rethrow;
    }
  }
}
