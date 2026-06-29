import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class WatchVehiclePositionUseCase {
  const WatchVehiclePositionUseCase(this._repository);

  final LiveTripsRepository _repository;

  Stream<VehiclePosition> call(String tripId) =>
      _repository.watchVehiclePosition(tripId);
}
