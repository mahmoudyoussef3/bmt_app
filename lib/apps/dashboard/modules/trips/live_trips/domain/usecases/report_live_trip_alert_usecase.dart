import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class ReportLiveTripAlertUseCase {
  final LiveTripsRepository _repository;

  const ReportLiveTripAlertUseCase(this._repository);

  Future<LiveTrip> call({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) {
    return _repository.reportAlert(
      tripId: tripId,
      type: type,
      severity: severity,
      title: title,
      message: message,
    );
  }
}
