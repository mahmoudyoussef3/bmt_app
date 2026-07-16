import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_history_usecase.dart';
import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  TripHistoryCubit(this._getHistory) : super(const TripHistoryLoading());

  final GetTripHistoryUseCase _getHistory;

  Future<void> load() async {
    emit(const TripHistoryLoading());
    try {
      final trips = await _getHistory();
      if (isClosed) return;
      emit(TripHistoryLoaded(trips));
    } catch (e) {
      if (isClosed) return;
      emit(TripHistoryError(e.toString()));
    }
  }

  /// Re-fetches quietly, keeping the current list on screen — a pull-to-
  /// refresh that flashed back to the loading skeleton every time would be a
  /// jarring way to check for one new completed trip. Falls back to [load]
  /// only when there's nothing loaded yet to refresh.
  Future<void> refresh() async {
    if (state is! TripHistoryLoaded) return load();
    try {
      final trips = await _getHistory();
      if (isClosed) return;
      emit(TripHistoryLoaded(trips));
    } catch (_) {
      // Keep showing the current list on a silent refresh failure.
    }
  }
}
