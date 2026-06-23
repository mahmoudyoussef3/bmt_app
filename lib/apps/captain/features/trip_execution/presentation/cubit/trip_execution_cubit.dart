import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../../domain/usecases/complete_trip_usecase.dart';
import '../../domain/usecases/start_boarding_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import '../../../live_location/domain/usecases/stop_location_sharing_usecase.dart';
import 'trip_execution_state.dart';

class TripExecutionCubit extends Cubit<TripExecutionCubitState> {
  TripExecutionCubit({
    required StartBoardingUseCase startBoarding,
    required StartTripUseCase startTrip,
    required CompleteTripUseCase completeTrip,
    required StopLocationSharingUseCase stopLocationSharing,
  }) : _startBoarding = startBoarding,
       _startTrip = startTrip,
       _completeTrip = completeTrip,
       _stopLocationSharing = stopLocationSharing,
       super(const TripExecutionIdle(TripExecutionStatus.scheduled));

  final StartBoardingUseCase _startBoarding;
  final StartTripUseCase _startTrip;
  final CompleteTripUseCase _completeTrip;
  final StopLocationSharingUseCase _stopLocationSharing;
  TripExecutionStatus _status = TripExecutionStatus.scheduled;

  void setInitialStatus(TripExecutionStatus status) {
    _status = status;
    emit(TripExecutionIdle(status));
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
      
      // Auto-stop location sharing when trip finishes
      try {
        await _stopLocationSharing(tripId);
      } catch (_) {
        // ignore errors stopping sharing
      }
      
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString(), _status));
    }
  }
}
