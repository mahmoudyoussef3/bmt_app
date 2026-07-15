import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_seat_selection_data_usecase.dart';
import '../../domain/usecases/lock_trip_seat_usecase.dart';
import '../../domain/usecases/select_seat_usecase.dart';
import 'seat_selection_state.dart';

class SeatSelectionCubit extends Cubit<SeatSelectionState> {
  SeatSelectionCubit({
    required GetSeatSelectionDataUseCase getSeatSelectionData,
    required SelectSeatUseCase selectSeat,
    required LockTripSeatUseCase lockTripSeat,
  }) : _getSeatSelectionData = getSeatSelectionData,
       _selectSeat = selectSeat,
       _lockTripSeat = lockTripSeat,
       super(const SeatSelectionLoading());

  final GetSeatSelectionDataUseCase _getSeatSelectionData;
  final SelectSeatUseCase _selectSeat;
  final LockTripSeatUseCase _lockTripSeat;

  Future<void> loadSeatSelection(String tripId) async {
    emit(const SeatSelectionLoading());
    try {
      final data = await _getSeatSelectionData(tripId);
      emit(SeatSelectionLoaded(data: data));
    } catch (error) {
      emit(SeatSelectionError(error.toString()));
    }
  }

  void selectSeat(String seatId) {
    final current = state;
    if (current is! SeatSelectionLoaded) return;
    final selectedSeatId = _selectSeat(
      seats: current.data.seats,
      currentSeatId: current.selectedSeatId,
      seatId: seatId,
    );
    emit(
      current.copyWith(
        selectedSeatId: selectedSeatId,
        clearSelectedSeat: selectedSeatId == null,
        clearLockedSeat: selectedSeatId != current.lockedSeatId,
        clearLockError: true,
      ),
    );
  }

  Future<bool> lockSelectedSeat() async {
    final current = state;
    if (current is! SeatSelectionLoaded) return false;
    final seatId = current.selectedSeatId;
    if (seatId == null || seatId.trim().isEmpty) return false;
    if (current.lockedSeatId == seatId) return true;

    emit(current.copyWith(isLocking: true, clearLockError: true));
    try {
      await _lockTripSeat(tripId: current.data.tripId, seatId: seatId);
      final latest = state;
      if (latest is SeatSelectionLoaded) {
        emit(
          latest.copyWith(
            lockedSeatId: seatId,
            isLocking: false,
            clearLockError: true,
          ),
        );
      }
      return true;
    } catch (error) {
      final latest = state;
      if (latest is SeatSelectionLoaded) {
        emit(
          latest.copyWith(
            isLocking: false,
            lockError: _lockErrorMessage(error),
          ),
        );
      }
      return false;
    }
  }

  /// Keeps the raw error code (e.g. `seat_unavailable`) in state; the
  /// presentation layer maps it to a localized, user-friendly message since
  /// this cubit has no BuildContext to resolve AppLocalizations with.
  String _lockErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('seat_unavailable')) {
      return 'seat_unavailable';
    }
    return message.replaceFirst(RegExp(r'^Exception: ?'), '');
  }
}
