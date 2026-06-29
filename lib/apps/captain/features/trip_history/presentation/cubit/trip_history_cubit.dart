import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_history_usecase.dart';
import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  TripHistoryCubit(this._getHistory) : super(const TripHistoryLoading());

  final GetTripHistoryUseCase _getHistory;

  Future<void> load() async {
    emit(const TripHistoryLoading());
    try {
      emit(TripHistoryLoaded(await _getHistory()));
    } catch (e) {
      emit(TripHistoryError(e.toString()));
    }
  }

  Future<void> refresh() => load();
}
