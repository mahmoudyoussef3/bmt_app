import '../../../shared/domain/entities/operation_trip.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class GetTripEventsUseCase {
  final TripsRepository _repository;

  const GetTripEventsUseCase(this._repository);

  Future<List<TripEvent>> call(String tripId) {
    return _repository.getTripEvents(tripId);
  }
}
