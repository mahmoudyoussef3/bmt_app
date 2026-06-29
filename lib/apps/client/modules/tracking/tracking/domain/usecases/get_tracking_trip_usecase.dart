import '../entities/tracking_trip.dart';
import '../repositories/tracking_repository.dart';

class GetTrackingTripUseCase {
  const GetTrackingTripUseCase(this._repository);

  final TrackingRepository _repository;

  Future<TrackingTripData> call({String? bookingId, String? tripId}) {
    return _repository.getTrackingTrip(bookingId: bookingId, tripId: tripId);
  }
}
