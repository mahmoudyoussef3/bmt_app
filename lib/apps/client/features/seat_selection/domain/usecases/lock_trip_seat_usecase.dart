import '../repositories/seat_selection_repository.dart';

class LockTripSeatUseCase {
  final SeatSelectionRepository _repository;

  const LockTripSeatUseCase(this._repository);

  /// Reserves a seat for 5 minutes.
  /// Returns {seat_id, lock_expires_at} on success.
  /// Throws 'seat_unavailable' if seat is already taken.
  Future<Map<String, dynamic>> call({
    required String tripId,
    required String seatId,
  }) {
    return _repository.lockTripSeat(tripId: tripId, seatId: seatId);
  }
}
