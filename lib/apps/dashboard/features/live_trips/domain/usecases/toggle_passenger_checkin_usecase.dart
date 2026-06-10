import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class TogglePassengerCheckinUseCase {
  final LiveTripsRepository _repository;

  const TogglePassengerCheckinUseCase(this._repository);

  Future<LiveTrip> call(String tripId, String passengerId) =>
      _repository.togglePassengerCheckin(tripId, passengerId);
}
