import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Calls the update_trip_status RPC which enforces the valid transition
  /// machine and logs a trip_events entry — all in one transaction.
  Future<void> _transitionStatus(String tripId, String newStatus) async {
    try {
      await _supabase.rpc('update_trip_status', params: {
        'p_trip_id':    tripId,
        'p_new_status': newStatus,
      });
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
}
