import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/vehicle_feed.dart';
import '../models/tracking_point_model.dart';

/// The realtime half of tracking: live GPS fixes, the health of the link
/// carrying them, and a change signal for every table that can alter what the
/// screen shows.
class TrackingRealtime {
  const TrackingRealtime(this._client);

  final SupabaseClient _client;

  /// Tables whose rows change what the rider sees — a status flip, a captain's
  /// station arrival, a check-in, a re-sequenced stop. Any of them firing means
  /// the joined view is stale and must be refetched.
  ///
  /// One channel covering all of them, deliberately: the screen renders a single
  /// joined view, so there is one thing to invalidate, and a second subscription
  /// per table would only give several ways to arrive at the same refetch.
  static const _tripScopedTables = [
    'operation_bookings',
    'trip_events',
    'trip_passengers',
    'trip_route_points',
    'trip_seats',
    // The station board: arrivals, departures and boarding tallies. This is what
    // makes "✓ تم المرور" and the next stop's ETA move on the rider's screen the
    // moment the captain leaves a station.
    'trip_station_progress',
  ];

  /// Positions **and** link health on one stream.
  ///
  /// Until this carried status, `subscribe()` was called with no callback
  /// anywhere in the codebase, so nothing could tell a healthy socket from a
  /// dead one. That is why the client ended up polling unconditionally: a real
  /// "the map never moves" bug was fixed by adding a safety net, because there
  /// was no way to see whether the socket itself was the problem. Reporting
  /// status is what lets the poll become a fallback instead of a fixture.
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId) {
    final controller = StreamController<VehicleFeedEvent>.broadcast();

    void emit(VehicleFeedEvent event) {
      if (!controller.isClosed) controller.add(event);
    }

    final channel = _client
        .channel('location_updates:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_live_locations',
          filter: _tripFilter('trip_id', tripId),
          callback: (change) {
            try {
              emit(VehicleFixReported(
                TrackingPointModel.fromRow(change.newRecord),
              ));
            } catch (_) {
              // A row we cannot parse is not a reason to tear the feed down.
            }
          },
        );

    final subscribed = channel.subscribe((status, error) {
      emit(VehicleLinkChanged(_linkFor(status)));
    });

    controller.onCancel = () => subscribed.unsubscribe();
    return controller.stream;
  }

  /// Supabase's subscribe states, reduced to the three the domain cares about.
  ///
  /// `closed` is deliberately `degraded` rather than `lost`: the client library
  /// closes and re-opens a channel while reconnecting, so treating every close as
  /// a dead link would flap the rider's status pill on an ordinary network blip.
  /// Genuinely dead is what the freshness timer decides.
  TrackingLink _linkFor(RealtimeSubscribeStatus status) => switch (status) {
    RealtimeSubscribeStatus.subscribed => TrackingLink.connected,
    RealtimeSubscribeStatus.closed => TrackingLink.degraded,
    RealtimeSubscribeStatus.timedOut => TrackingLink.degraded,
    RealtimeSubscribeStatus.channelError => TrackingLink.lost,
  };

  Stream<void> watchTripChanges(String tripId) {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client.channel('client_tracking:$tripId');

    for (final table in _tripScopedTables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: _tripFilter('trip_id', tripId),
        callback: notify,
      );
    }

    final subscribed = channel.subscribe();
    controller.onCancel = subscribed.unsubscribe;
    return controller.stream;
  }

  PostgresChangeFilter _tripFilter(String column, String value) =>
      PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: column,
        value: value,
      );
}
