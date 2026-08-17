import 'dart:async';

import '../entities/tracking_trip.dart';

abstract class TrackingRepository {
  Future<TrackingTripData> getTrackingTrip({String? bookingId, String? tripId});

  /// Live positions and the health of the link delivering them, on one stream.
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId);

  Stream<void> watchTripChanges(String tripId);

  /// The rider confirming they have boarded. Server-validated: their own
  /// booking, paid for, and only while the vehicle is standing at their stop.
  Future<void> confirmBoarding(String bookingId);
}
