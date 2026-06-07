import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_live_trips_usecase.dart';
import 'live_trips_state.dart';

class LiveTripsCubit extends Cubit<LiveTripsState> {
  final GetLiveTripsUseCase _getLiveTrips;

  LiveTripsCubit(this._getLiveTrips) : super(const LiveTripsLoading());

  Future<void> load() async {
    emit(const LiveTripsLoading());
    try {
      final trips = await _getLiveTrips();
      emit(LiveTripsLoaded(trips: trips, selectedTripId: trips.first.id));
    } catch (error) {
      emit(LiveTripsError(error.toString()));
    }
  }

  void selectTrip(String tripId) {
    final current = state;
    if (current is! LiveTripsLoaded) return;
    emit(current.copyWith(selectedTripId: tripId));
  }
}
