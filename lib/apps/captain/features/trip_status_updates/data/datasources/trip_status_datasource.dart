import '../../domain/entities/captain_trip_status.dart';
import '../models/trip_status_model.dart';

class TripStatusDataSource {
  const TripStatusDataSource();

  Future<TripStatusModel> updateStatus(
    String tripId,
    CaptainTripStatus status,
  ) async {
    return TripStatusModel(tripId: tripId, status: status);
  }
}
