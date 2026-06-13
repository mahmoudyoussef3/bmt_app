import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_seat_selection_data_usecase.dart';
import '../../domain/usecases/select_seat_usecase.dart';
import 'seat_selection_state.dart';

class SeatSelectionCubit extends Cubit<SeatSelectionState> {
  SeatSelectionCubit({
    required GetSeatSelectionDataUseCase getSeatSelectionData,
    required SelectSeatUseCase selectSeat,
  }) : _getSeatSelectionData = getSeatSelectionData,
       _selectSeat = selectSeat,
       super(const SeatSelectionLoading());

  final GetSeatSelectionDataUseCase _getSeatSelectionData;
  final SelectSeatUseCase _selectSeat;

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
      SeatSelectionLoaded(data: current.data, selectedSeatId: selectedSeatId),
    );
  }
}
