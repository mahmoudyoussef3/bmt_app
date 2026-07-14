import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/tracking_trip.dart';
import '../models/tracking_trip_assembler.dart';
import 'tracking_datasource.dart';
import 'tracking_realtime.dart';
import 'tracking_trip_query.dart';

class SupabaseTrackingDatasource implements TrackingDatasource {
  SupabaseTrackingDatasource(this._client)
    : _query = TrackingTripQuery(_client),
      _realtime = TrackingRealtime(_client);

  final SupabaseClient _client;
  final TrackingTripQuery _query;
  final TrackingRealtime _realtime;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const TrackingTripData.none();

    final booking = await _query.findBooking(
      userId: userId,
      bookingId: bookingId,
      tripId: tripId,
    );
    final resolvedTripId = booking?['trip_id'] as String?;
    final resolvedBookingId = booking?['id']?.toString();
    if (resolvedTripId == null || resolvedBookingId == null) {
      return const TrackingTripData.none();
    }

    final results = await Future.wait<dynamic>([
      _query.routePoints(resolvedTripId),
      _query.trip(resolvedTripId),
      _query.latestLocation(resolvedTripId),
      _query.events(resolvedTripId),
      _query.passenger(resolvedTripId, userId),
      _query.hasReview(resolvedBookingId),
    ]);

    return TrackingTripAssembler.assemble(
      tripId: resolvedTripId,
      bookingId: resolvedBookingId,
      pointRows: results[0] as List<Map<String, dynamic>>,
      tripRow: results[1] as Map<String, dynamic>?,
      locationRow: results[2] as Map<String, dynamic>?,
      eventRows: results[3] as List<Map<String, dynamic>>,
      passengerRow: results[4] as Map<String, dynamic>?,
      hasReview: results[5] as bool,
    );
  }

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) =>
      _realtime.watchVehiclePosition(tripId);

  @override
  Stream<void> watchTripChanges(String tripId) =>
      _realtime.watchTripChanges(tripId);
}
