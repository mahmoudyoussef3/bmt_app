import '../../domain/entities/trip_execution_state.dart';

sealed class TripExecutionCubitState {
  const TripExecutionCubitState();
}

class TripExecutionIdle extends TripExecutionCubitState {
  const TripExecutionIdle(this.snapshot);

  final TripExecutionSnapshot snapshot;
}

class TripExecutionLoading extends TripExecutionCubitState {
  const TripExecutionLoading(this.previousSnapshot);

  final TripExecutionSnapshot previousSnapshot;
}

class TripExecutionError extends TripExecutionCubitState {
  const TripExecutionError(this.message, this.previousSnapshot);

  final String message;
  final TripExecutionSnapshot previousSnapshot;
}
