import '../entities/seat_option.dart';

class SelectSeatUseCase {
  const SelectSeatUseCase();

  String? call({
    required List<SeatOption> seats,
    required String? currentSeatId,
    required String seatId,
  }) {
    final seat = seats.firstWhere(
      (seat) => seat.id == seatId,
      orElse: () => const SeatOption(
        id: '',
        seatNumber: 0,
        availability: SeatAvailability.reserved,
      ),
    );
    if (!seat.isAvailable) return currentSeatId;
    return currentSeatId == seatId ? null : seatId;
  }
}
