import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/core/tracking/live_tracking_config.dart';

import '../../domain/entities/tracking_trip.dart';
import '../models/tracking_point_model.dart';
import '../models/tracking_trip_assembler.dart';
import 'tracking_datasource.dart';
import 'tracking_realtime.dart';
import 'tracking_trip_query.dart';

class SupabaseTrackingDatasource implements TrackingDatasource {
  SupabaseTrackingDatasource(
    this._client, {
    LiveTrackingConfig config = kLiveTrackingConfig,
  }) : _query = TrackingTripQuery(_client),
       _realtime = TrackingRealtime(_client),
       _config = config;

  final SupabaseClient _client;
  final TrackingTripQuery _query;
  final TrackingRealtime _realtime;
  final LiveTrackingConfig _config;

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

  /// Positions and link health, with a catch-up poll that runs **only while the
  /// socket is unhealthy**.
  ///
  /// This used to poll every 8 s unconditionally, alongside realtime, forever.
  /// That was the right fix for a real bug — riders were watching frozen maps —
  /// but it was made blind, because nothing reported whether the socket was
  /// working. Now that `TrackingRealtime` surfaces status, the redundancy can be
  /// spent only when it is earning something: while the link is `connected`
  /// there are no periodic queries at all, and the moment it is not, the poll
  /// fires immediately and then keeps pace until the socket returns.
  ///
  /// Re-emitting an already-seen fix stays harmless — the progress engine rejects
  /// any fix that is not strictly newer than the last one it folded in, so a
  /// catch-up poll landing a position realtime also delivered changes nothing.
  @override
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId) {
    late StreamController<VehicleFeedEvent> controller;
    StreamSubscription<VehicleFeedEvent>? feedSub;
    Timer? poll;

    void emit(VehicleFeedEvent event) {
      if (!controller.isClosed) controller.add(event);
    }

    Future<void> pollOnce() async {
      try {
        final point = TrackingPointModel.fromNullableRow(
          await _query.latestLocation(tripId),
        );
        if (point != null) emit(VehicleFixReported(point));
      } catch (_) {
        // A transient read failure must not end the poll — the next tick retries.
      }
    }

    void stopPoll() {
      poll?.cancel();
      poll = null;
    }

    void startPoll({required bool immediately}) {
      if (poll != null) return;
      if (immediately) unawaited(pollOnce());
      poll = Timer.periodic(
        _config.reconnectPollInterval,
        (_) => unawaited(pollOnce()),
      );
    }

    controller = StreamController<VehicleFeedEvent>(
      onListen: () {
        // Armed but not fired: until the socket reports in we do not know whether
        // it is coming up, and the trip fetch has already seeded the last known
        // position. If it never connects, the first tick covers for it.
        startPoll(immediately: false);

        feedSub = _realtime.watchVehicleFeed(tripId).listen(
          (event) {
            if (event is VehicleLinkChanged) {
              if (event.link.isConnected) {
                stopPoll();
              } else {
                startPoll(immediately: true);
              }
            }
            emit(event);
          },
          onError: (Object error, StackTrace stackTrace) {
            startPoll(immediately: true);
            emit(const VehicleLinkChanged(TrackingLink.lost));
          },
        );
      },
      onCancel: () {
        stopPoll();
        final active = feedSub;
        feedSub = null;
        return active?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<void> watchTripChanges(String tripId) =>
      _realtime.watchTripChanges(tripId);
}
