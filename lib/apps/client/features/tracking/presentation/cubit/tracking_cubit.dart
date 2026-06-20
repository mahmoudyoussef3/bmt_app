import 'dart:async';

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
  Timer? _liveRefreshTimer;
  String? _bookingId;
  String? _tripId;

  Future<void> load({String? bookingId, String? tripId}) async {
    _bookingId = bookingId;
    _tripId = tripId;
    _liveRefreshTimer?.cancel();
    emit(const TrackingLoading());
    try {
      final data = await _getTrackingTrip(bookingId: bookingId, tripId: tripId);
      final state = data.tripState;
      emit(
        TrackingLoaded(
          data: data,
          currentState: state,
          title: _getTrackingTitle(state),
        ),
      );
      _scheduleLiveRefreshIfNeeded(state);
    } catch (error) {
      emit(TrackingError(error.toString()));
    }
  }

  Future<void> refresh() => _refresh(silent: false);

  Future<void> _refresh({required bool silent}) async {
    final current = state;
    if (current is TrackingLoaded && silent) {
      emit(current.copyWith(isRefreshing: true));
    }

    try {
      final data = await _getTrackingTrip(
        bookingId: _bookingId,
        tripId: _tripId,
      );
      final nextState = data.tripState;
      final loaded = state is TrackingLoaded ? state as TrackingLoaded : null;
      emit(
        TrackingLoaded(
          data: data,
          currentState: nextState,
          title: _getTrackingTitle(nextState),
          ratings: loaded?.ratings ?? const TrackingRatings(),
        ),
      );
      _scheduleLiveRefreshIfNeeded(nextState);
    } catch (error) {
      if (!silent) emit(TrackingError(error.toString()));
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

  void _scheduleLiveRefreshIfNeeded(TrackingTripState state) {
    _liveRefreshTimer?.cancel();
    if (state == TrackingTripState.completed) return;
    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refresh(silent: true),
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

  @override
  Future<void> close() {
    _liveRefreshTimer?.cancel();
    return super.close();
  }
}
