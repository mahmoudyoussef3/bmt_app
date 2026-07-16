import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/core/tracking/progress/arrival_events.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../models/trip_execution_model.dart';

class TripExecutionDataSource {
  const TripExecutionDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<TripExecutionModel> startBoarding(String tripId) async {
    await _transitionStatus(tripId, 'boarding');
    return TripExecutionModel(
      tripId: tripId,
      status: TripExecutionStatus.boarding,
    );
  }

  Future<TripExecutionModel> startTrip(String tripId) async {
    await _transitionStatus(tripId, 'in_progress');
    return TripExecutionModel(
      tripId: tripId,
      status: TripExecutionStatus.inProgress,
    );
  }

  Future<TripExecutionModel> completeTrip(String tripId) async {
    await _transitionStatus(tripId, 'completed');
    return TripExecutionModel(
      tripId: tripId,
      status: TripExecutionStatus.completed,
    );
  }

  /// Watches this trip's status, boarded/passenger counts, and confirmed
  /// station arrivals, re-fetching the aggregate snapshot on every relevant
  /// change so none of them go stale for the lifetime of the execution
  /// screen. `trip_passengers`/`trip_events` changes aren't filtered to this
  /// trip at the channel level (Realtime only supports a single equality
  /// filter, already spent on `operation_trips.id`) — the same trade-off
  /// `CaptainTripRemoteDataSource.watchTripUpdates` makes; the debounced
  /// re-fetch below is what actually scopes the result to [tripId].
  Stream<TripExecutionSnapshot> watchSnapshot({
    required String tripId,
    required int routePointCount,
  }) {
    final controller = StreamController<TripExecutionSnapshot>.broadcast();
    Timer? debounce;

    Future<void> emitSnapshot() async {
      if (controller.isClosed) return;
      try {
        final snapshot = await _fetchSnapshot(tripId, routePointCount);
        if (!controller.isClosed) controller.add(snapshot);
      } catch (_) {
        // Realtime is a refinement over the initial fetch already shown by
        // the screen; a transient refresh failure just waits for the next
        // change (or the next manual reopen) rather than surfacing an error
        // over data the captain can already see.
      }
    }

    void scheduleEmit() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), emitSnapshot);
    }

    final channel = _supabase
        .channel('captain_trip_execution:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'operation_trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (_) => scheduleEmit(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_passengers',
          callback: (_) => scheduleEmit(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_events',
          callback: (_) => scheduleEmit(),
        )
        .subscribe();

    controller.onCancel = () {
      debounce?.cancel();
      channel.unsubscribe();
    };

    emitSnapshot();
    return controller.stream;
  }

  Future<TripExecutionSnapshot> _fetchSnapshot(
    String tripId,
    int routePointCount,
  ) async {
    final response = await _supabase
        .from('operation_trips')
        .select('status, trip_passengers(status), trip_events(title)')
        .eq('id', tripId)
        .single();

    final status =
        _mapStatus(response['status']?.toString()) ??
        TripExecutionStatus.scheduled;

    final passengers = (response['trip_passengers'] as List?) ?? const [];
    // scan_passenger_ticket writes 'confirmed' on check-in (see
    // migration_07) — trip_passengers.status has no 'boarded' value in its
    // check constraint. 'completed' is kept defensively; nothing currently
    // writes it, but it would mean the same thing if something one day did.
    final boarded = passengers.where((p) {
      final s = (p as Map<String, dynamic>)['status']?.toString();
      return s == 'confirmed' || s == 'completed';
    }).length;

    final events = (response['trip_events'] as List?) ?? const [];
    final arrivalEventCount = countStationArrivalEvents(
      events.map((e) => (e as Map<String, dynamic>)['title'] as String?),
    );

    return TripExecutionSnapshot(
      status: status,
      passengerCount: passengers.length,
      boardedCount: boarded,
      arrivedStationsCount: stationArrivalFloor(
        arrivalEventCount: arrivalEventCount,
        routePointCount: routePointCount,
      ),
    );
  }

  /// Inserts the canonical per-station arrival marker into `trip_events` —
  /// the exact convention the Dashboard uses (`markPointArrived`), so
  /// Dashboard, Client, and Captain all read the same source of truth.
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  }) async {
    await _supabase.from('trip_events').insert({
      'trip_id': tripId,
      'title': kStationArrivalEventTitle,
      'description': 'وصلت الرحلة إلى محطة: $pointName',
      'done': true,
    });
  }

  /// Calls the update_trip_status RPC which enforces the valid transition
  /// machine and logs a trip_events entry — all in one transaction.
  Future<void> _transitionStatus(String tripId, String newStatus) async {
    try {
      await _supabase.rpc(
        'update_trip_status',
        params: {'p_trip_id': tripId, 'p_new_status': newStatus},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('invalid_transition')) {
        throw Exception('حالة الرحلة لا تسمح بهذا الانتقال');
      }
      if (e.message.contains('trip_not_found')) {
        throw Exception('الرحلة غير موجودة');
      }
      rethrow;
    }
  }

  TripExecutionStatus? _mapStatus(String? status) {
    return switch (status) {
      'scheduled' || 'open_for_booking' => TripExecutionStatus.scheduled,
      'boarding' => TripExecutionStatus.boarding,
      'in_progress' => TripExecutionStatus.inProgress,
      'completed' => TripExecutionStatus.completed,
      _ => null,
    };
  }
}
