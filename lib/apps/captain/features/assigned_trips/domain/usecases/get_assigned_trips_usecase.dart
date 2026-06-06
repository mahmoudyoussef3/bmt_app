import '../entities/assigned_trip.dart';
import '../repositories/captain_trip_repository.dart';

class GetAssignedTripsUseCase {
  const GetAssignedTripsUseCase(this._repository);

  final CaptainTripRepository _repository;

  Future<List<AssignedTrip>> call() {
    return _repository.getAssignedTrips();
  }
}
