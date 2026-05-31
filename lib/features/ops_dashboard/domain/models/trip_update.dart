import 'position.dart';
import 'trip.dart';

class TripUpdate {
  final String tripId;
  final TripStatus status;
  final double progress; // 0.0 - 1.0
  final Position? location;

  TripUpdate({
    required this.tripId,
    required this.status,
    this.progress = 0.0,
    this.location,
  });
}
