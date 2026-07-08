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

  Stream<TripExecutionStatus> watchTripStatus(String tripId) {
    final controller = StreamController<TripExecutionStatus>.broadcast();
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
          callback: (change) {
            final status = _mapStatus(change.newRecord['status']?.toString());
            if (status != null && !controller.isClosed) {
              controller.add(status);
            }
          },
        )
        .subscribe();
    controller.onCancel = channel.unsubscribe;
    return controller.stream;
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
