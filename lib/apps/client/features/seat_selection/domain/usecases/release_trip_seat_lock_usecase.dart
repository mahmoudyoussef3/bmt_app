import '../repositories/seat_selection_repository.dart';

class ReleaseTripSeatLockUseCase {
  final SeatSelectionRepository _repository;

  const ReleaseTripSeatLockUseCase(this._repository);

  /// Hands a seat lock back after a booking attempt failed, so the seat does
  /// not sit reserved-but-unbooked until its lock expires. A seat that already
  /// carries a booking is left alone by the RPC.
  Future<void> call({required String tripId, required String seatId}) {
    return _repository.releaseTripSeatLock(tripId: tripId, seatId: seatId);
  }
}
