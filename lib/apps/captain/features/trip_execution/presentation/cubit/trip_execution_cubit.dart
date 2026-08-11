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
