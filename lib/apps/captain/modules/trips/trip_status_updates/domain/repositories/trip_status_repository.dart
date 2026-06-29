import '../entities/captain_trip_status.dart';

abstract class TripStatusRepository {
  Future<CaptainTripStatusUpdate> updateStatus(
    String tripId,
    CaptainTripStatus status,
  );
}
