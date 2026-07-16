import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_stops_usecase.dart';
import 'trip_history_detail_state.dart';

class TripHistoryDetailCubit extends Cubit<TripHistoryDetailState> {
  TripHistoryDetailCubit(this._getTripStops)
    : super(const TripHistoryDetailLoading());

  final GetTripStopsUseCase _getTripStops;

  Future<void> load(String tripId) async {
    emit(const TripHistoryDetailLoading());
    try {
      final stops = await _getTripStops(tripId);
      if (isClosed) return;
      emit(TripHistoryDetailLoaded(stops));
    } catch (e) {
      if (isClosed) return;
      emit(TripHistoryDetailError(e.toString()));
    }
  }
}
