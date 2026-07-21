import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}
