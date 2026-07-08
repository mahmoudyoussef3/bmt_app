import '../repositories/trip_execution_repository.dart';

/// Persists the captain's "arrived at station" action so the Dashboard and
/// Client apps see it live — replaces what used to be a purely local
/// `setState` counter with no backend effect.
class MarkStationArrivedUseCase {
  const MarkStationArrivedUseCase(this._repository);

  final TripExecutionRepository _repository;

  Future<void> call({
    required String tripId,
    required String pointId,
    required String pointName,
  }) => _repository.markStationArrived(
    tripId: tripId,
    pointId: pointId,
    pointName: pointName,
  );
}
