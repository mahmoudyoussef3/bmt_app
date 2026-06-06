import '../../domain/entities/captain_trip_status.dart';

class TripStatusModel {
  const TripStatusModel({required this.tripId, required this.status});

  final String tripId;
  final CaptainTripStatus status;

  CaptainTripStatusUpdate toEntity() {
    return CaptainTripStatusUpdate(tripId: tripId, status: status);
  }
}
