import 'dart:async';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._datasource);

  final TrackingDatasource _datasource;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) {
    return _datasource.getTrackingTrip(bookingId: bookingId, tripId: tripId);
  }

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) =>
      _datasource.watchVehiclePosition(tripId);

  @override
  Stream<void> watchTripChanges(String tripId) =>
      _datasource.watchTripChanges(tripId);
}
