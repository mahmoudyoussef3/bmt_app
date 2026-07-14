import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/tracking_point.dart';
import '../models/tracking_point_model.dart';

/// The realtime half of tracking: live GPS fixes, and a change signal for
/// every table that can alter what the screen shows.
class TrackingRealtime {
  const TrackingRealtime(this._client);

  final SupabaseClient _client;

  /// Tables whose rows change what the rider sees — a status flip, a captain's
  /// station arrival, a check-in, a re-sequenced stop. Any of them firing means
  /// the joined view is stale and must be refetched.
  static const _tripScopedTables = [
    'operation_bookings',
    'trip_events',
    'trip_passengers',
    'trip_route_points',
    'trip_seats',
  ];

  Stream<TrackingPoint> watchVehiclePosition(String tripId) {
    final controller = StreamController<TrackingPoint>.broadcast();
    final channel = _client
        .channel('location_updates:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_live_locations',
          filter: _tripFilter('trip_id', tripId),
          callback: (change) {
            try {
              controller.add(TrackingPointModel.fromRow(change.newRecord));
            } catch (_) {
              // One malformed fix must not tear down the live stream.
            }
          },
        )
        .subscribe();
    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  Stream<void> watchTripChanges(String tripId) {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client
        .channel('client_tracking:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          filter: _tripFilter('id', tripId),
          callback: notify,
        );

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
