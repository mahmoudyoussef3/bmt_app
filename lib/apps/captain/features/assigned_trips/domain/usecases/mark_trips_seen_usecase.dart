import '../repositories/seen_trips_repository.dart';

class MarkTripsSeenUseCase {
  const MarkTripsSeenUseCase(this._repository);

  final SeenTripsRepository _repository;

  Future<void> call(Set<String> tripIds) => _repository.markSeen(tripIds);
}
