import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/station_board_mapper.dart';

import '../../domain/entities/station_action_failure.dart';
import '../../domain/entities/station_passenger.dart';

/// The captain's half of `trip_station_progress`: one realtime read of the
/// board, and the three RPCs that move it.
///
/// Every mutation is an RPC. There is no write policy on the table at all, so
/// this is not a convention that could be worked around — it is the only path
/// that exists.
class StationProgressDataSource {
  const StationProgressDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// The board, re-read whenever any of its rows change.
  ///
  /// One channel, filtered to this trip. The rows carry their own boarding
  /// tallies, so a rider confirming boarding lands here without a second
  /// subscription to the manifest — which is what keeps the captain's screen and
  /// the rider's phone from telling two different stories.
  Stream<StationBoard> watchBoard(String tripId) {
    final controller = StreamController<StationBoard>.broadcast();
    Timer? debounce;

    Future<void> emit() async {
      if (controller.isClosed) return;
      try {
        final board = await fetchBoard(tripId);
        if (!controller.isClosed) controller.add(board);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    void schedule() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 200), emit);
    }

    final channel = _supabase
        .channel('captain_station_progress:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_station_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (_) => schedule(),
        )
        .subscribe();

    controller.onCancel = () {
      debounce?.cancel();
      channel.unsubscribe();
    };

    emit();
    return controller.stream;
  }

  Future<StationBoard> fetchBoard(String tripId) async {
    final rows = await _supabase
        .from('trip_station_progress')
        .select(StationBoardMapper.columns)
        .eq('trip_id', tripId)
        .order('sequence', ascending: true);

    return StationBoardMapper.fromRows(
      (rows as List).cast<Map<String, dynamic>>(),
    );
  }

  Future<void> arriveAtStation(String tripId) =>
      _rpc('captain_arrive_station', {'p_trip_id': tripId});

  Future<void> departStation(String tripId) =>
      _rpc('captain_depart_station', {'p_trip_id': tripId});

  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) => _rpc('captain_resolve_no_show', {
    'p_trip_passenger_id': passengerId,
    'p_reason': reason.wireValue,
    'p_note': note,
  });

  /// Everyone due to board at one station.
  ///
  /// Matched on `pickup_point_id` when the manifest carries one, falling back to
  /// the point name — the same two-step match the database makes, because trips
  /// created before the point id was recorded still have riders on them.
  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) async {
    final query = _supabase
        .from('trip_passengers')
        .select('id, passenger_name, seat_label, phone, status')
        .eq('trip_id', tripId);

    final rows =
        await (routePointId != null && routePointId.isNotEmpty
                ? query.eq('pickup_point_id', routePointId)
                : query.eq('pickup_point_name', pointName))
            .order('seat_label', ascending: true);

    return [
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        StationPassenger(
          id: row['id']?.toString() ?? '',
          name: (row['passenger_name'] as String? ?? '').trim(),
          seatLabel: (row['seat_label'] as String? ?? '').trim(),
          phone: (row['phone'] as String? ?? '').trim(),
          status: stationPassengerStatusFrom(row['status']?.toString()),
        ),
    ];
  }

  /// Every refusal reaches the cubit as a [StationActionException], so the UI
  /// never has to read a Postgres string to find out whether the vehicle is
  /// held by passengers or by the clock.
  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      await _supabase.rpc(name, params: params);
    } on PostgrestException catch (error) {
      throw stationFailureFrom(error.message);
    }
  }
}
