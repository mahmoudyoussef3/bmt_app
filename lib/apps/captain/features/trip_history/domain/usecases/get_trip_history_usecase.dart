import '../entities/trip_history_item.dart';
import '../repositories/trip_history_repository.dart';

class GetTripHistoryUseCase {
  const GetTripHistoryUseCase(this._repository);

  final TripHistoryRepository _repository;

  Future<List<TripHistoryItem>> call() => _repository.getTripHistory();
}
