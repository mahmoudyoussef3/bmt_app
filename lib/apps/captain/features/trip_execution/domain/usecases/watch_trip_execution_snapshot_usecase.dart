import '../entities/trip_execution_state.dart';
import '../repositories/trip_execution_repository.dart';

class WatchTripExecutionSnapshotUseCase {
  const WatchTripExecutionSnapshotUseCase(this._repository);

  final TripExecutionRepository _repository;

  Stream<TripExecutionSnapshot> call({
    required String tripId,
    required int routePointCount,
  }) => _repository.watchTripSnapshot(
    tripId: tripId,
    routePointCount: routePointCount,
  );
}
