import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../../domain/usecases/complete_trip_usecase.dart';
import '../../domain/usecases/mark_station_arrived_usecase.dart';
import '../../domain/usecases/start_boarding_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import '../../domain/usecases/watch_trip_execution_snapshot_usecase.dart';
import 'trip_execution_state.dart';

const _initialSnapshot = TripExecutionSnapshot(
  status: TripExecutionStatus.scheduled,
  passengerCount: 0,
  boardedCount: 0,
  arrivedStationsCount: 0,
);

class TripExecutionCubit extends Cubit<TripExecutionCubitState> {
  TripExecutionCubit({
    required StartBoardingUseCase startBoarding,
    required StartTripUseCase startTrip,
    required CompleteTripUseCase completeTrip,
    required WatchTripExecutionSnapshotUseCase watchTripSnapshot,
    required MarkStationArrivedUseCase markStationArrived,
  }) : _startBoarding = startBoarding,
       _startTrip = startTrip,
       _completeTrip = completeTrip,
       _watchTripSnapshot = watchTripSnapshot,
       _markStationArrived = markStationArrived,
       super(const TripExecutionIdle(_initialSnapshot));

  final StartBoardingUseCase _startBoarding;
  final StartTripUseCase _startTrip;
  final CompleteTripUseCase _completeTrip;
  final WatchTripExecutionSnapshotUseCase _watchTripSnapshot;
  final MarkStationArrivedUseCase _markStationArrived;
  StreamSubscription<TripExecutionSnapshot>? _subscription;
  TripExecutionSnapshot _snapshot = _initialSnapshot;

  /// Starts watching [tripId]. [initialSnapshot] (derived from the trip the
  /// captain tapped on the home list) is shown immediately so the screen
  /// never opens blank; the live watch then takes over as the source of
  /// truth for status, boarded/passenger counts, and arrived stations for as
  /// long as this screen stays open — none of them stay frozen at whatever
  /// they were when the screen was pushed.
  void watch({
    required String tripId,
    required int routePointCount,
    required TripExecutionSnapshot initialSnapshot,
  }) {
    _snapshot = initialSnapshot;
    emit(TripExecutionIdle(_snapshot));
    _subscription?.cancel();
    _subscription =
        _watchTripSnapshot(
          tripId: tripId,
          routePointCount: routePointCount,
        ).listen((snapshot) {
          if (isClosed) return;
          _snapshot = snapshot;
          emit(TripExecutionIdle(snapshot));
        }, onError: (_) {});
  }

  Future<void> board(String tripId) async {
    emit(TripExecutionLoading(_snapshot));
    try {
      final result = await _startBoarding(tripId);
      if (isClosed) return;
      _snapshot = _snapshot.copyWith(status: result.status);
      emit(TripExecutionIdle(_snapshot));
    } catch (error) {
      if (isClosed) return;
      emit(TripExecutionError(error.toString(), _snapshot));
    }
  }

  Future<void> start(String tripId) async {
    emit(TripExecutionLoading(_snapshot));
    try {
      final result = await _startTrip(tripId);
      if (isClosed) return;
      _snapshot = _snapshot.copyWith(status: result.status);
      emit(TripExecutionIdle(_snapshot));
    } catch (error) {
      if (isClosed) return;
      emit(TripExecutionError(error.toString(), _snapshot));
    }
  }

  Future<void> complete(String tripId) async {
    emit(TripExecutionLoading(_snapshot));
    try {
      final result = await _completeTrip(tripId);
      if (isClosed) return;
      _snapshot = _snapshot.copyWith(status: result.status);
      emit(TripExecutionIdle(_snapshot));
    } catch (error) {
      if (isClosed) return;
      emit(TripExecutionError(error.toString(), _snapshot));
    }
  }

  /// Persists a station arrival. Deliberately does not touch [state]: this
  /// is a per-stop side action independent from the board/start/complete
  /// lifecycle, so it must not flash the main action button into a loading
  /// state. Callers (the next-stop banner) track their own local
  /// submitting/error UI; the live watch picks up the resulting `trip_events`
  /// insert and corrects `arrivedStationsCount` on its own.
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  }) {
    return _markStationArrived(
      tripId: tripId,
      pointId: pointId,
      pointName: pointName,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
