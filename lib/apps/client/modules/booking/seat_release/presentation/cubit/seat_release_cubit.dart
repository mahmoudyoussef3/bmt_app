import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_seat_release_data_usecase.dart';
import 'seat_release_state.dart';

class SeatReleaseCubit extends Cubit<SeatReleaseState> {
  SeatReleaseCubit(this._getSeatReleaseData)
    : super(const SeatReleaseLoading());

  final GetSeatReleaseDataUseCase _getSeatReleaseData;

  Future<void> load() async {
    emit(const SeatReleaseLoading());
    try {
      final data = await _getSeatReleaseData();
      emit(SeatReleaseLoaded(data));
    } catch (error) {
      emit(SeatReleaseError(error.toString()));
    }
  }
}
