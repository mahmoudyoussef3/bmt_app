import '../../domain/entities/seat_option.dart';

sealed class SeatSelectionState {
  const SeatSelectionState();
}

class SeatSelectionLoading extends SeatSelectionState {
  const SeatSelectionLoading();
}

class SeatSelectionLoaded extends SeatSelectionState {
  const SeatSelectionLoaded({
    required this.data,
    this.selectedSeatId,
    this.lockedSeatId,
    this.isLocking = false,
    this.lockError,
  });

  final SeatSelectionData data;
  final String? selectedSeatId;
  final String? lockedSeatId;
  final bool isLocking;
  final String? lockError;

  double get total => selectedSeatId == null ? 0 : data.pricePerSeat;

  SeatSelectionLoaded copyWith({
    SeatSelectionData? data,
    String? selectedSeatId,
    String? lockedSeatId,
    bool clearSelectedSeat = false,
    bool clearLockedSeat = false,
    bool? isLocking,
    String? lockError,
    bool clearLockError = false,
  }) {
    return SeatSelectionLoaded(
      data: data ?? this.data,
      selectedSeatId: clearSelectedSeat
          ? null
          : selectedSeatId ?? this.selectedSeatId,
      lockedSeatId: clearLockedSeat ? null : lockedSeatId ?? this.lockedSeatId,
      isLocking: isLocking ?? this.isLocking,
      lockError: clearLockError ? null : lockError ?? this.lockError,
    );
  }
}

class SeatSelectionError extends SeatSelectionState {
  const SeatSelectionError(this.message);

  final String message;
}
