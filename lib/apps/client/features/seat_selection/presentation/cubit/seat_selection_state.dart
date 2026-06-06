import '../../domain/entities/seat_option.dart';

sealed class SeatSelectionState {
  const SeatSelectionState();
}

class SeatSelectionLoading extends SeatSelectionState {
  const SeatSelectionLoading();
}

class SeatSelectionLoaded extends SeatSelectionState {
  const SeatSelectionLoaded({required this.data, this.selectedSeatId});

  final SeatSelectionData data;
  final String? selectedSeatId;

  double get total => selectedSeatId == null ? 0 : data.pricePerSeat;
}

class SeatSelectionError extends SeatSelectionState {
  const SeatSelectionError(this.message);

  final String message;
}
