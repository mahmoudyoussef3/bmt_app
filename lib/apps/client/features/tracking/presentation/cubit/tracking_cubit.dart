import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/get_tracking_title_usecase.dart';
import '../../domain/usecases/get_tracking_trip_usecase.dart';
import '../../domain/usecases/watch_vehicle_position_usecase.dart';
import '../../domain/usecases/watch_tracking_trip_usecase.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required GetTrackingTripUseCase getTrackingTrip,
    required GetTrackingTitleUseCase getTrackingTitle,
    required WatchVehiclePositionUseCase watchVehiclePosition,
    required WatchTrackingTripUseCase watchTrackingTrip,
  }) : _getTrackingTrip = getTrackingTrip,
       _getTrackingTitle = getTrackingTitle,
       _watchVehiclePosition = watchVehiclePosition,
       _watchTrackingTrip = watchTrackingTrip,
       super(const TrackingLoading());

  final GetTrackingTripUseCase _getTrackingTrip;
  final GetTrackingTitleUseCase _getTrackingTitle;
  final WatchVehiclePositionUseCase _watchVehiclePosition;
  final WatchTrackingTripUseCase _watchTrackingTrip;

  StreamSubscription<TrackingPoint>? _locationSub;
  StreamSubscription<void>? _tripChangesSub;
  Timer? _refreshDebounce;
  String? _subscribedTripId;
  String? _subscribedChangesTripId;
  String? _bookingId;
  String? _tripId;

  Future<void> load({String? bookingId, String? tripId}) async {
    _bookingId = bookingId;
    _tripId = tripId;
    _cancelLocationSubscription();
    _cancelTripChangesSubscription();
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
      if (data.tripId != null) {
        _subscribeToLocationIfNeeded(state, data.tripId!);
        _subscribeToTripChanges(data.tripId!);
      }
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
      if (data.tripId != null) {
        _subscribeToLocationIfNeeded(nextState, data.tripId!);
        _subscribeToTripChanges(data.tripId!);
      }
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

  void _subscribeToLocationIfNeeded(TrackingTripState state, String tripId) {
    if (state == TrackingTripState.completed) {
      _cancelLocationSubscription();
      return;
    }

    // If we're already subscribed to THIS trip, do nothing.
    if (_subscribedTripId == tripId && _locationSub != null) return;

    // Cancel any existing subscription for a DIFFERENT trip.
    _cancelLocationSubscription();

    _subscribedTripId = tripId;
    _locationSub = _watchVehiclePosition(tripId).listen(
      (point) {
        final current = this.state;
        if (current is! TrackingLoaded) return;
        final data = current.data;
        final nextState = current.currentState == TrackingTripState.notStarted
            ? TrackingTripState.driverOnWay
            : current.currentState;
        emit(
          current.copyWith(
            currentState: nextState,
            title: _getTrackingTitle(nextState),
            data: data.copyWith(
              tripState: nextState,
              vehicleLatitude: point.latitude,
              vehicleLongitude: point.longitude,
              vehicleLocationAt: point.recordedAt ?? DateTime.now(),
            ),
          ),
        );
      },
      onError: (error, stackTrace) {
        debugPrint('Realtime location subscription error: $error');
      },
    );
  }

  void _subscribeToTripChanges(String tripId) {
    if (_subscribedChangesTripId == tripId && _tripChangesSub != null) return;
    _cancelTripChangesSubscription();
    _subscribedChangesTripId = tripId;
    _tripChangesSub = _watchTrackingTrip(tripId).listen(
      (_) {
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 250),
          () => _refresh(silent: true),
        );
      },
      onError: (error, stackTrace) {
        debugPrint('Realtime trip subscription error: $error');
      },
    );
  }

  void _cancelLocationSubscription() {
    _locationSub?.cancel();
    _locationSub = null;
    _subscribedTripId = null;
  }

  void _cancelTripChangesSubscription() {
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _tripChangesSub?.cancel();
    _tripChangesSub = null;
    _subscribedChangesTripId = null;
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
    _cancelLocationSubscription();
    _cancelTripChangesSubscription();
    return super.close();
  }
}
