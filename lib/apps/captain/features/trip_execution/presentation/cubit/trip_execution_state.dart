import '../../domain/entities/trip_execution_state.dart';

sealed class TripExecutionCubitState {
  const TripExecutionCubitState();

  TripExecutionSnapshot get snapshot => switch (this) {
    TripExecutionIdle(:final snapshot) => snapshot,
    TripExecutionLoading(:final previousSnapshot) => previousSnapshot,
    TripExecutionError(:final previousSnapshot) => previousSnapshot,
  };
}

class TripExecutionIdle extends TripExecutionCubitState {
  const TripExecutionIdle(this.snapshot);

  @override
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
