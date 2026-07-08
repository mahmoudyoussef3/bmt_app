import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/progress/arrival_events.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_engine.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

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
  Timer? _etaTicker;
  RouteProgressEngine? _engine;
  String? _engineTripId;
  int _engineStopCount = 0;
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
          progress: _syncEngine(data, state),
        ),
      );
      if (data.tripId != null) {
        _subscribeToLocationIfNeeded(state, data.tripId!);
        _subscribeToTripChanges(data.tripId!);
      }
      _startEtaTicker();
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
          progress: _syncEngine(data, nextState),
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
    _engine?.updatePhase(_phaseFor(state));
    emit(
      current.copyWith(
        currentState: state,
        title: _getTrackingTitle(state),
        progress: _engine?.snapshot(DateTime.now()),
        ratings: state == TrackingTripState.completed
            ? const TrackingRatings()
            : current.ratings,
      ),
    );
  }

  TripProgressPhase _phaseFor(TrackingTripState state) => switch (state) {
    TrackingTripState.notStarted ||
    TrackingTripState.driverOnWay => TripProgressPhase.headingToPickup,
    TrackingTripState.boarding => TripProgressPhase.boarding,
    TrackingTripState.inProgress => TripProgressPhase.enRoute,
    TrackingTripState.completed => TripProgressPhase.completed,
  };

  /// Keeps one progress engine alive per trip so stop states stay monotonic
  /// across silent refreshes; rebuilds only when the trip or its stop list
  /// actually changes. Returns a fresh snapshot for the emitted state.
  RouteProgressSnapshot? _syncEngine(
    TrackingTripData data,
    TrackingTripState state,
  ) {
    final now = DateTime.now();
    final rebuild =
        _engine == null ||
        _engineTripId != data.tripId ||
        _engineStopCount != data.routeStops.length;
    if (rebuild) {
      _engine = RouteProgressEngine(
        stops: data.routeStops,
        scheduledDeparture: data.departureAt,
        scheduledArrival: data.arrivalAt,
        phase: _phaseFor(state),
      );
      _engineTripId = data.tripId;
      _engineStopCount = data.routeStops.length;
    } else {
      _engine!.updatePhase(_phaseFor(state));
    }
    // Seed the captain-reported arrival floor before layering GPS on top —
    // same convention as the Dashboard, so per-stop state never regresses
    // below what the captain has explicitly confirmed.
    final arrivalFloor = stationArrivalFloor(
      arrivalEventCount: data.arrivalEventCount,
      routePointCount: data.routeStops.length,
    );
    if (arrivalFloor > 0) _engine!.seedVisited(arrivalFloor);
    final fix = data.vehicleFix;
    if (fix != null) {
      _engine!.addFix(
        latitude: fix.latitude,
        longitude: fix.longitude,
        speedKmh: data.vehicleSpeedKmh,
        now: now,
      );
    }
    return _engine!.snapshot(now);
  }

  /// ETAs are moments in time; re-emit periodically so countdown labels and
  /// staleness flags stay honest between fixes.
  void _startEtaTicker() {
    _etaTicker?.cancel();
    _etaTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      final current = state;
      final engine = _engine;
      if (current is! TrackingLoaded || engine == null) return;
      if (current.currentState == TrackingTripState.completed) return;
      emit(current.copyWith(progress: engine.snapshot(DateTime.now())));
    });
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
        final now = DateTime.now();
        final data = current.data;
        final nextState = current.currentState == TrackingTripState.notStarted
            ? TrackingTripState.driverOnWay
            : current.currentState;
        _engine?.updatePhase(_phaseFor(nextState));
        _engine?.addFix(
          latitude: point.latitude,
          longitude: point.longitude,
          speedKmh: point.speed == null || point.speed! < 0
              ? null
              : point.speed! * 3.6,
          now: now,
        );
        emit(
          current.copyWith(
            currentState: nextState,
            title: _getTrackingTitle(nextState),
            progress: _engine?.snapshot(now),
            data: data.copyWith(
              tripState: nextState,
              vehicleLatitude: point.latitude,
              vehicleLongitude: point.longitude,
              vehicleHeading: point.heading,
              vehicleSpeed: point.speed,
              vehicleAccuracy: point.accuracy,
              vehicleLocationAt: point.recordedAt ?? now,
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
    _etaTicker?.cancel();
    _cancelLocationSubscription();
    _cancelTripChangesSubscription();
    return super.close();
  }
}
