import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../../domain/usecases/complete_trip_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import 'trip_execution_state.dart';

class TripExecutionCubit extends Cubit<TripExecutionCubitState> {
  TripExecutionCubit({
    required StartTripUseCase startTrip,
    required CompleteTripUseCase completeTrip,
  }) : _startTrip = startTrip,
       _completeTrip = completeTrip,
       super(const TripExecutionIdle(TripExecutionStatus.scheduled));

  final StartTripUseCase _startTrip;
  final CompleteTripUseCase _completeTrip;

  Future<void> start(String tripId) async {
    emit(const TripExecutionLoading());
    try {
      final result = await _startTrip(tripId);
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString()));
    }
  }

  Future<void> complete(String tripId) async {
    emit(const TripExecutionLoading());
    try {
      final result = await _completeTrip(tripId);
      emit(TripExecutionIdle(result.status));
    } catch (error) {
      emit(TripExecutionError(error.toString()));
    }
  }
}
