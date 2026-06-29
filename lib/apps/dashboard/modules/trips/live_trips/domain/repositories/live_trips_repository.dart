import '../entities/live_trip.dart';

abstract class LiveTripsRepository {
  Future<List<LiveTrip>> getLiveTrips();
  Future<LiveTrip> getLiveTripDetails(String tripId);

  Future<LiveTrip> startTrip(String tripId);
  Future<LiveTrip> pauseTrip(String tripId);
  Future<LiveTrip> resumeTrip(String tripId);
  Future<LiveTrip> completeTrip(String tripId);

  Future<LiveTrip> markPointArrived(String tripId, String pointId);
  Future<LiveTrip> markPointCompleted(String tripId, String pointId);
  Future<LiveTrip> skipPoint(String tripId, String pointId);

  Future<LiveTrip> resolveAlert(String tripId, String alertId);

  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  });

  Future<String> callDriver(String driverPhone);
  Future<String> sendDriverMessage(String driverPhone, String message);
  Future<LiveTrip> togglePassengerCheckin(String tripId, String passengerId);
  Stream<VehiclePosition> watchVehiclePosition(String tripId);
  Stream<void> watchTripStatusChanges();
}
