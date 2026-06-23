import 'dart:async';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/supabase_tracking_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._datasource);

  final TrackingDatasource _datasource;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    final model = await _datasource.getTrackingTrip(
      bookingId: bookingId,
      tripId: tripId,
    );
    return model.toEntity();
  }

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) {
    return _datasource.watchVehiclePosition(tripId).map((model) => model.toEntity());
  }
}
