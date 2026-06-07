import '../entities/operation_trip.dart';
import '../repositories/trips_repository.dart';

class GetOperationTripsUseCase {
  final TripsRepository _repository;

  const GetOperationTripsUseCase(this._repository);

  Future<List<OperationTrip>> call() {
    return _repository.getTrips();
  }
}
