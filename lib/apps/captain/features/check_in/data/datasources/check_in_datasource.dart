import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/check_in_result.dart';
import '../models/check_in_model.dart';

class CheckInDataSource {
  const CheckInDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Validates a passenger QR code and marks them as checked in.
  /// QR payload: booking_id (UUID).
  /// Idempotent: safe to call multiple times for the same passenger
  /// (handles offline retry scenarios).
  Future<CheckInModel> checkPassenger({
    required String tripId,
    required String bookingId,
    required CheckInStatus status,
  }) async {
    final driver = _supabase.auth.currentUser;
    if (driver == null) throw Exception('Driver not authenticated');

    final driverRecord = await _supabase
        .from('drivers')
        .select('id')
        .eq('user_id', driver.id)
        .maybeSingle();

    if (driverRecord == null) {
      throw Exception('Driver profile not found for authenticated user');
    }

    final driverId = driverRecord['id'] as String;

    try {
      final response = await _supabase.rpc('scan_passenger_ticket', params: {
        'p_trip_id':    tripId,
        'p_booking_id': bookingId,
        'p_driver_id':  driverId,
      });

      return CheckInModel.fromRpcResponse(
        tripId: tripId,
        passengerId: bookingId,
        response: Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
      return CheckInModel(
        tripId: tripId,
        passengerId: bookingId,
        status: CheckInStatus.absent,
        errorMessage: e.message,
      );
    }
  }
}
