import '../repositories/seen_trips_repository.dart';

class GetSeenTripIdsUseCase {
  const GetSeenTripIdsUseCase(this._repository);

  final SeenTripsRepository _repository;

  Future<Set<String>> call() => _repository.getSeenTripIds();
}
