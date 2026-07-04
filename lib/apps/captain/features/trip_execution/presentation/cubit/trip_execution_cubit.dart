import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../../domain/usecases/complete_trip_usecase.dart';
import '../../domain/usecases/start_boarding_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import '../../domain/usecases/watch_trip_execution_status_usecase.dart';
import 'trip_execution_state.dart';

class TripExecutionCubit extends Cubit<TripExecutionCubitState> {
  TripExecutionCubit({
    required StartBoardingUseCase startBoarding,
    required StartTripUseCase startTrip,
    required CompleteTripUseCase completeTrip,
    required WatchTripExecutionStatusUseCase watchTripStatus,
  }) : _startBoarding = startBoarding,
       _startTrip = startTrip,
       _completeTrip = completeTrip,
       _watchTripStatus = watchTripStatus,
       super(const TripExecutionIdle(TripExecutionStatus.scheduled));

  final StartBoardingUseCase _startBoarding;
  final StartTripUseCase _startTrip;
  final CompleteTripUseCase _completeTrip;
  final WatchTripExecutionStatusUseCase _watchTripStatus;
  StreamSubscription<TripExecutionStatus>? _statusSubscription;
  TripExecutionStatus _status = TripExecutionStatus.scheduled;

  void setInitialStatus(TripExecutionStatus status) {
    _status = status;
    emit(TripExecutionIdle(status));
  }

  void watch(String tripId, TripExecutionStatus initialStatus) {
    setInitialStatus(initialStatus);
    _statusSubscription?.cancel();
    _statusSubscription = _watchTripStatus(tripId).listen((status) {
      if (isClosed || status == _status) return;
      _status = status;
      emit(TripExecutionIdle(status));
    }, onError: (_) {});
  }

  Future<void> board(String tripId) async {
    emit(TripExecutionLoading(_status));
    try {
      final result = await _startBoarding(tripId);
      _status = result.status;
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString(), _status));
    }
  }

  Future<void> start(String tripId) async {
    emit(TripExecutionLoading(_status));
    try {
      final result = await _startTrip(tripId);
      _status = result.status;
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString(), _status));
    }
  }

  Future<void> complete(String tripId) async {
    emit(TripExecutionLoading(_status));
    try {
      final result = await _completeTrip(tripId);
      _status = result.status;
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString(), _status));
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
