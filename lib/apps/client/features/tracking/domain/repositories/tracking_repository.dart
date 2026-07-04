import 'dart:async';

import '../entities/tracking_trip.dart';

abstract class TrackingRepository {
  Future<TrackingTripData> getTrackingTrip({String? bookingId, String? tripId});

  Stream<TrackingPoint> watchVehiclePosition(String tripId);

  Stream<void> watchTripChanges(String tripId);
}
