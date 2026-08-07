import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../domain/entities/reassignment_target.dart';
import '../models/operation_booking_model.dart';
import 'bookings_datasource.dart';

/// Reads and reviews real client bookings from `operation_bookings`, enriched
/// with the trip, route, driver, vehicle and package they reference. All state
/// transitions go through the audited SECURITY DEFINER RPCs so seat holds,
/// passenger records and notifications stay consistent — the dashboard never
/// writes booking status columns directly.
class SupabaseBookingsDatasource implements BookingsDatasource {
  final SupabaseClient _client;

  const SupabaseBookingsDatasource(this._client);

  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    try {
      final response = await _client
          .from('operation_bookings')
          .select(OperationBookingModel.columns)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OperationBookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String? note,
  ) async {
    try {
      await _client.rpc(
        'office_approve_payment',
        params: {'p_booking_id': bookingId, 'p_note': note?.trim() ?? ''},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reason,
  ) async {
    try {
      await _client.rpc(
        'office_reject_payment',
        params: {'p_booking_id': bookingId, 'p_reason': reason.trim()},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reason,
  ) async {
    try {
      await _client.rpc(
        'office_request_payment_review',
        params: {'p_booking_id': bookingId, 'p_note': reason.trim()},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<OperationBookingModel>> bulkApprove(
    List<String> bookingIds,
    String? note,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await approveBooking(id, note));
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> bulkReject(
    List<String> bookingIds,
    String reason,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await rejectBooking(id, reason));
    }
    return updated;
  }

  @override
  Future<List<ReassignmentTarget>> fetchReassignmentTargets() async {
    try {
      final rows = await _client
          .from('operation_trips')
          .select('id, trip_date, departure_time, operation_routes(name)')
          .inFilter('status', const ['scheduled', 'open_for_booking'])
          .gte('trip_date', DateTime.now().toIso8601String().split('T').first)
          .order('trip_date')
          .order('departure_time')
          .limit(100);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        final route = map['operation_routes'] as Map<String, dynamic>?;
        return ReassignmentTarget(
          tripId: map['id'] as String,
          routeName: (route?['name'] as String?) ?? 'مسار غير معروف',
          tripDate: (map['trip_date'] as String?) ?? '',
          departureTime: (map['departure_time'] as String?) ?? '',
        );
      }).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> reassignBooking(
    String bookingId,
    String newTripId,
  ) async {
    try {
      await _client.rpc(
        'office_reassign_booking',
        params: {'p_booking_id': bookingId, 'p_new_trip_id': newTripId},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<List<OperationBookingModel>> watchBookings() {
    // The realtime stream only carries base-table rows, so every change
    // triggers an enriched re-read to keep joined trip/package data current.
    return _client
        .from('operation_bookings')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchBookings());
  }

  Future<OperationBookingModel> _refetch(String bookingId) async {
    final response = await _client
        .from('operation_bookings')
        .select(OperationBookingModel.columns)
        .eq('id', bookingId)
        .single();
    return OperationBookingModel.fromJson(response);
  }

  Exception _handleError(dynamic error) {
    // `bookings` is trigger-gated on operation_bookings, and reassignment runs
    // through office_reassign_booking, which the same gate covers.
    LicensingGuard.check(error);

    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}
