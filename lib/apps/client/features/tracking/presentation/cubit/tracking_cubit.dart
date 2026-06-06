import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/get_tracking_title_usecase.dart';
import '../../domain/usecases/get_tracking_trip_usecase.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required GetTrackingTripUseCase getTrackingTrip,
    required GetTrackingTitleUseCase getTrackingTitle,
  }) : _getTrackingTrip = getTrackingTrip,
       _getTrackingTitle = getTrackingTitle,
       super(const TrackingLoading());

  final GetTrackingTripUseCase _getTrackingTrip;
  final GetTrackingTitleUseCase _getTrackingTitle;

  Future<void> load() async {
    emit(const TrackingLoading());
    try {
      final data = await _getTrackingTrip();
      emit(
        TrackingLoaded(
          data: data,
          currentState: TrackingTripState.notStarted,
          title: _getTrackingTitle(TrackingTripState.notStarted),
        ),
      );
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  void changeState(TrackingTripState state) {
    final current = this.state;
    if (current is! TrackingLoaded) return;
    emit(
      current.copyWith(
        currentState: state,
        title: _getTrackingTitle(state),
        ratings: state == TrackingTripState.completed
            ? const TrackingRatings()
            : current.ratings,
      ),
    );
  }

  void rateDriver(int rating) => _updateRatings(driver: rating);

  void rateVehicle(int rating) => _updateRatings(vehicle: rating);

  void rateRoute(int rating) => _updateRatings(route: rating);

  void _updateRatings({int? driver, int? vehicle, int? route}) {
    final current = state;
    if (current is! TrackingLoaded) return;
    emit(
      current.copyWith(
        ratings: current.ratings.copyWith(
          driver: driver,
          vehicle: vehicle,
          route: route,
        ),
      ),
    );
  }
}
