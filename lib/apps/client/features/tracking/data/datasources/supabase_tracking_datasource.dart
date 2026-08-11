import 'package:async/async.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/tracking_trip.dart';
import '../models/tracking_point_model.dart';
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
      _query.stations(resolvedTripId),
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
      stationRows: results[6] as List<Map<String, dynamic>>,
      bookingStatus: booking?['status']?.toString(),
    );
  }

  /// "نعم، صعدت".
  ///
  /// The app checks nothing here — the rider owns this booking, the vehicle is
  /// at their station, the booking is paid for, and none of that is decided in
  /// Dart. `passenger_confirm_boarding` checks all three and refuses otherwise;
  /// the screen's job is to make the button unavailable when it already knows
  /// the answer, not to be the answer.
  @override
  Future<void> confirmBoarding(String bookingId) async {
    try {
      await _client.rpc(
        'passenger_confirm_boarding',
        params: {'p_booking_id': bookingId},
      );
    } on PostgrestException catch (error) {
      throw Exception(_boardingFailure(error.message));
    }
  }

  String _boardingFailure(String message) {
    if (message.contains('vehicle_not_at_station')) {
      return 'لم تصل السيارة إلى محطتك بعد';
    }
    if (message.contains('not_your_station')) {
      return 'السيارة الآن في محطة أخرى — انتظر وصولها إلى محطتك';
    }
    if (message.contains('not_your_booking')) {
      return 'لا يمكنك تأكيد صعود حجز لا يخصك';
    }
    if (message.contains('booking_not_boardable')) {
      return 'حالة حجزك لا تسمح بتأكيد الصعود';
    }
    if (message.contains('trip_not_running')) {
      return 'لم تبدأ الرحلة بعد';
    }
    return 'تعذر تأكيد الصعود، حاول مجدداً';
  }

  /// Realtime delivers a fix the instant the captain shares it; the poll is a
  /// safety net so a dropped socket, an expired realtime token, or a single
  /// missed event can never leave the rider on a frozen map while the captain
  /// is still sending. Re-emitting an already-seen fix is harmless — the
  /// vehicle engine rejects any fix that is not strictly newer than the last
  /// one it drew, so only genuinely new positions ever move the marker.
  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) {
    final live = _realtime.watchVehiclePosition(tripId);
    final polled = Stream.periodic(_pollInterval)
        .asyncMap((_) => _latestOrNull(tripId))
        .map(TrackingPointModel.fromNullableRow)
        .where((point) => point != null)
        .cast<TrackingPoint>();
    return StreamGroup.merge([live, polled]);
  }

  /// A transient read failure must not end the poll — the next tick retries.
  Future<Map<String, dynamic>?> _latestOrNull(String tripId) async {
    try {
      return await _query.latestLocation(tripId);
    } catch (_) {
      return null;
    }
  }

  static const _pollInterval = Duration(seconds: 8);

  @override
  Stream<void> watchTripChanges(String tripId) =>
      _realtime.watchTripChanges(tripId);
}
