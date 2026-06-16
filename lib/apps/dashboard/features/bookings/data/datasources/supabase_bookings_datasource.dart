import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/operation_booking.dart';
import '../models/operation_booking_model.dart';
import 'bookings_datasource.dart';

class SupabaseBookingsDatasource implements BookingsDatasource {
  final SupabaseClient _client;

  const SupabaseBookingsDatasource(this._client);

  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    try {
      final response = await _client
          .from('operation_bookings')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OperationBookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      // Create a timeline event for this action
      final event = BookingTimelineEventModel(
        timestamp: DateTime.now(),
        action: 'تم تحديث الحالة إلى ${status.label}',
        actor: 'النظام',
      );

      // Fetch existing timeline to append
      final existing = await _client
          .from('operation_bookings')
          .select('timeline')
          .eq('id', bookingId)
          .single();
          
      final List<dynamic> currentTimeline = existing['timeline'] as List<dynamic>? ?? [];
      currentTimeline.insert(0, event.toJson());

      final response = await _client
          .from('operation_bookings')
          .update({
            'status': status.name,
            'timeline': currentTimeline,
          })
          .eq('id', bookingId)
          .select()
          .single();

      return OperationBookingModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) async {
    try {
      // Single UPDATE via RPC instead of N sequential round-trips
      await _client.rpc('bulk_update_booking_status', params: {
        'p_booking_ids': bookingIds,
        'p_new_status':  status.name,
      });

      // Re-fetch the updated rows to return current state
      final response = await _client
          .from('operation_bookings')
          .select()
          .inFilter('id', bookingIds);

      return (response as List)
          .map((json) => OperationBookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) async {
    try {
      final updated = <OperationBookingModel>[];
      for (final id in bookingIds) {
        final event = BookingTimelineEventModel(
          timestamp: DateTime.now(),
          action: 'تم الإسناد إلى رحلة $tripId',
          actor: 'النظام',
        );

        final existing = await _client
            .from('operation_bookings')
            .select('timeline')
            .eq('id', id)
            .single();
            
        final List<dynamic> currentTimeline = existing['timeline'] as List<dynamic>? ?? [];
        currentTimeline.insert(0, event.toJson());

        final response = await _client
            .from('operation_bookings')
            .update({
              'assigned_trip': tripId,
              'timeline': currentTimeline,
            })
            .eq('id', id)
            .select()
            .single();
            
        updated.add(OperationBookingModel.fromJson(response));
      }
      return updated;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  ) async {
    try {
      // RPC atomically updates booking status AND transitions trip_seats to 'paid'.
      // This prevents the booking being approved while the seat stays 'reserved'.
      await _client.rpc('approve_booking', params: {
        'p_booking_id':    bookingId,
        'p_reviewer_name': reviewer,
      });

      // Append to timeline (non-critical audit trail, separate from atomic write)
      final event = BookingTimelineEventModel(
        timestamp: DateTime.now(),
        action: 'تم قبول الدفع',
        actor: reviewer,
        note: note,
      );
      final existing = await _client
          .from('operation_bookings')
          .select('timeline')
          .eq('id', bookingId)
          .single();
      final List<dynamic> timeline = existing['timeline'] as List<dynamic>? ?? [];
      timeline.insert(0, event.toJson());
      await _client
          .from('operation_bookings')
          .update({'timeline': timeline})
          .eq('id', bookingId);

      final response = await _client
          .from('operation_bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return OperationBookingModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) async {
    try {
      // RPC atomically updates booking status, releases the seat, and decrements
      // the trip counter — all in one transaction.
      await _client.rpc('reject_booking', params: {
        'p_booking_id':       bookingId,
        'p_rejection_reason': reason,
        'p_reviewer_name':    reviewer,
      });

      // Append to timeline (non-critical)
      final event = BookingTimelineEventModel(
        timestamp: DateTime.now(),
        action: 'تم رفض الدفع',
        actor: reviewer,
        note: '$reason${note != null ? ' - $note' : ''}',
      );
      final existing = await _client
          .from('operation_bookings')
          .select('timeline')
          .eq('id', bookingId)
          .single();
      final List<dynamic> timeline = existing['timeline'] as List<dynamic>? ?? [];
      timeline.insert(0, event.toJson());
      await _client
          .from('operation_bookings')
          .update({'timeline': timeline})
          .eq('id', bookingId);

      final response = await _client
          .from('operation_bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return OperationBookingModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  ) async {
    try {
      final event = BookingTimelineEventModel(
        timestamp: DateTime.now(),
        action: 'طلب إعادة رفع الإيصال',
        actor: reviewer,
        note: reason,
      );

      final existing = await _client
          .from('operation_bookings')
          .select('timeline')
          .eq('id', bookingId)
          .single();
          
      final List<dynamic> currentTimeline = existing['timeline'] as List<dynamic>? ?? [];
      currentTimeline.insert(0, event.toJson());

      final response = await _client
          .from('operation_bookings')
          .update({
            'status': BookingStatus.requestReupload.name,
            'reviewer_name': reviewer,
            'timeline': currentTimeline,
          })
          .eq('id', bookingId)
          .select()
          .single();

      return OperationBookingModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<List<OperationBookingModel>> watchBookings() {
    return _client
        .from('operation_bookings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((json) => OperationBookingModel.fromJson(json))
              .toList(),
        );
  }

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}
