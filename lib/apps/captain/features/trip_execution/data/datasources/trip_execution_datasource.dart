import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../models/trip_execution_model.dart';

class TripExecutionDataSource {
  const TripExecutionDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<TripExecutionModel> startTrip(String tripId) async {
    await _updateTripStatus(tripId, 'in_progress', 'بدأ السائق الرحلة');
    return TripExecutionModel(
      tripId: tripId,
      status: TripExecutionStatus.inProgress,
    );
  }

  Future<TripExecutionModel> completeTrip(String tripId) async {
    await _updateTripStatus(tripId, 'completed', 'أنهى السائق الرحلة');
    return TripExecutionModel(
      tripId: tripId,
      status: TripExecutionStatus.completed,
    );
  }

  Future<void> _updateTripStatus(
    String tripId,
    String status,
    String eventTitle,
  ) async {
    await _supabase
        .from('operation_trips')
        .update({'status': status})
        .eq('id', tripId);
    await _supabase.from('trip_events').insert({
      'trip_id': tripId,
      'title': eventTitle,
      'description': eventTitle,
      'event_time': DateTime.now().toUtc().toIso8601String(),
      'done': true,
    });
  }
}
