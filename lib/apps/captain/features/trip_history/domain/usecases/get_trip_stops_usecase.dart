import '../entities/trip_history_stop.dart';
import '../repositories/trip_history_repository.dart';

class GetTripStopsUseCase {
  const GetTripStopsUseCase(this._repository);

  final TripHistoryRepository _repository;

  Future<List<TripHistoryStop>> call(String tripId) =>
      _repository.getTripStops(tripId);
}
