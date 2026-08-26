import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_seat.dart';
import '../../domain/entities/trip_stop.dart';
import '../mappers/trip_mapper.dart';
import '../mappers/trip_seat_mapper.dart';
import '../mappers/trip_stop_mapper.dart';
import '../models/trip_model.dart';
import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  const SupabaseTripsDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// The booking row plus its embedded trip, vehicle, driver and (RLS-scoped)
  /// review marker — the full shape [TripMapper] expects. The trip comes from
  /// `public_trips` (aliased to the key the mapper reads); its `*` already
  /// carries the sanitised `drivers` / `vehicles` jsonb columns, and the base
  /// table itself is closed to clients.
  static const _bookingSelect = '''
    *,
    operation_trips:public_trips (*, office:public_offices(name)),
    trip_reviews ( booking_id )
  ''';

  @override
  Future<List<TripModel>> getTrips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('operation_bookings')
        .select(_bookingSelect)
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    return response.map(TripMapper.fromBookingRow).toList();
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('operation_bookings')
        .select(_bookingSelect)
        .eq('client_id', user.id)
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final tripId =
        (response['operation_trips'] as Map<String, dynamic>?)?['id']
            ?.toString() ??
        '';
    final seatMap = await _loadSeatMap(
      tripId: tripId,
      mySeatLabel: response['seat']?.toString() ?? '',
    );
    final stops = await _loadStops(tripId: tripId, booking: response);

    return TripMapper.fromBookingRow(response, seatMap: seatMap, stops: stops);
  }

  /// Cancels the booking and hands its seat back to the trip. The RPC — not
  /// this call — decides whether cancelling is still allowed: it refuses once
  /// the dashboard has approved the payment.
  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _supabase.rpc(
        'cancel_booking_by_client',
        params: {'p_booking_id': bookingId, 'p_reason': reason},
      );
    } on PostgrestException catch (error) {
      throw Exception(_cancelErrorMessage(error.message));
    }
  }

  String _cancelErrorMessage(String raw) {
    if (raw.contains('booking_already_confirmed')) {
      return 'This booking is already paid and confirmed, so it can no longer '
          'be cancelled from the app. Please contact support.';
    }
    if (raw.contains('not_authorized')) {
      return 'You can only cancel your own bookings.';
    }
    if (raw.contains('booking_not_found')) {
      return 'This booking no longer exists.';
    }
    return 'Could not cancel the booking. Please try again.';
  }

  /// Loads the trip's real seat layout from `trip_seats`, flagging the
  /// passenger's own seat. Best-effort: a seat-map failure must never block the
  /// whole Trip Details screen, so it degrades to an empty layout.
  Future<List<TripSeat>> _loadSeatMap({
    required String tripId,
    required String mySeatLabel,
  }) async {
    if (tripId.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from('trip_seats')
          .select('seat_label, seat_row, seat_column, state')
          .eq('trip_id', tripId)
          .order('seat_row', ascending: true)
          .order('seat_column', ascending: true);

      return [
        for (var index = 0; index < rows.length; index++)
          TripSeatMapper.fromRow(
            rows[index],
            index: index,
            mySeatLabel: mySeatLabel,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The stations this trip calls at, from `trip_route_points` — the per-trip
  /// snapshot of the route's stops, so a corridor re-drawn after the ticket was
  /// sold still describes the journey the rider bought.
  ///
  /// The booking's own pickup/drop-off point comes along so the mapper can flag
  /// the two stops that are this rider's. Best-effort, like the seat map: a
  /// corridor that fails to load must never blank the whole Trip Details
  /// screen, so it degrades to no stops and the section simply isn't drawn.
  Future<List<TripStop>> _loadStops({
    required String tripId,
    required Map<String, dynamic> booking,
  }) async {
    if (tripId.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from('trip_route_points')
          .select(
            'id, route_point_id, point_name, point_order, '
            'arrival_offset, departure_offset, latitude, longitude',
          )
          .eq('trip_id', tripId)
          .order('point_order', ascending: true);

      return TripStopMapper.fromRows(
        rows,
        pickupPointId: booking['pickup_point_id']?.toString() ?? '',
        dropoffPointId: booking['dropoff_point_id']?.toString() ?? '',
        pickupPointName: booking['pickup_point_name']?.toString() ?? '',
        dropoffPointName: booking['dropoff_point_name']?.toString() ?? '',
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  Stream<void> watchTripChanges() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    final channel = _supabase
        .channel('client_trips:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_events',
          callback: notify,
        )
        .subscribe();

    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }
}
