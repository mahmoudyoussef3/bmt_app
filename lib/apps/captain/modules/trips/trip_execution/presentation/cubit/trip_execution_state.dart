import '../../domain/entities/trip_execution_state.dart';

sealed class TripExecutionCubitState {
  const TripExecutionCubitState();
}

class TripExecutionIdle extends TripExecutionCubitState {
  const TripExecutionIdle(this.status);

  final TripExecutionStatus status;
}

class TripExecutionLoading extends TripExecutionCubitState {
  const TripExecutionLoading(this.previousStatus);

  final TripExecutionStatus previousStatus;
}

class TripExecutionError extends TripExecutionCubitState {
  const TripExecutionError(this.message, this.previousStatus);

  final String message;
  final TripExecutionStatus previousStatus;
}
