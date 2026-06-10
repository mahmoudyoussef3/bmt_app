import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class ResolveLiveTripAlertUseCase {
  final LiveTripsRepository _repository;

  const ResolveLiveTripAlertUseCase(this._repository);

  Future<LiveTrip> call(String tripId, String alertId) =>
      _repository.resolveAlert(tripId, alertId);
}
