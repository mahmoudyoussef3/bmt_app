import '../../domain/entities/trip_execution_state.dart';

sealed class TripExecutionCubitState {
  const TripExecutionCubitState();

  /// The trip as last known, whatever the state.
  ///
  /// Every variant carries one — loading and error hold the snapshot from
  /// before they happened, so the screen keeps showing the trip rather than
  /// blanking out mid-drive. Exposing it here means callers read the trip
  /// without re-deriving it by switching over all three.
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
