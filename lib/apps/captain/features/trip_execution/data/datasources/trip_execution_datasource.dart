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
      } catch (_) {}
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
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_live_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
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
      lastLocation: await _fetchLastLocation(tripId),
    );
  }

  Future<TripLastLocationFix?> _fetchLastLocation(String tripId) async {
    final row = await _supabase
        .from('trip_live_locations')
        .select('latitude, longitude, recorded_at')
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;

    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final recordedAt = DateTime.tryParse(row['recorded_at']?.toString() ?? '');
    if (lat == null || lng == null || recordedAt == null) return null;

    return TripLastLocationFix(
      latitude: lat,
      longitude: lng,
      recordedAt: recordedAt.toLocal(),
    );
  }

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

  Future<void> _transitionStatus(String tripId, String newStatus) async {
    try {
      await _supabase.rpc(
        'captain_update_trip_status',
        params: {'p_trip_id': tripId, 'p_new_status': newStatus},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('invalid_transition')) {
        throw Exception('حالة الرحلة لا تسمح بهذا الانتقال');
      }
      if (e.message.contains('trip_not_found')) {
        throw Exception('الرحلة غير موجودة');
      }
      if (e.message.contains('not_your_trip') ||
          e.message.contains('not_a_captain') ||
          e.message.contains('status_not_allowed_for_captain')) {
        throw Exception('غير مصرح لك بتعديل هذه الرحلة');
      }
      rethrow;
    }
  }

  TripExecutionStatus? _mapStatus(String? status) {
    return switch (status) {
      'scheduled' => TripExecutionStatus.scheduled,
      'open_for_booking' => TripExecutionStatus.openForBooking,
      'boarding' => TripExecutionStatus.boarding,
      'in_progress' => TripExecutionStatus.inProgress,
      'completed' => TripExecutionStatus.completed,
      'cancelled' => TripExecutionStatus.cancelled,
      _ => null,
    };
  }
}
