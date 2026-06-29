import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/finance_payment.dart';
import '../mappers/booking_payment_mapper.dart';

class BookingPaymentsStore {
  const BookingPaymentsStore(this._client);

  final SupabaseClient _client;

  static const query = '''
    id, passenger_name, phone, status, created_at,
    payment_details, payment_receipt_url, notes, timeline,
    trip:operation_trips(trip_date, departure_time, route:operation_routes(name))
  ''';

  static const statuses = [
    'paymentUploaded',
    'underReview',
    'requestReupload',
    'approved',
    'rejected',
  ];

  Future<List<FinancePayment>> fetch() async {
    final rows = await _client
        .from('operation_bookings')
        .select(query)
        .inFilter('status', statuses)
        .order('created_at', ascending: false);
    return rows.map(mapBookingPayment).toList();
  }

  Future<FinancePayment> updateStatus(
    String id,
    PaymentReviewStatus status,
  ) async {
    if (status == PaymentReviewStatus.accepted) {
      await _client.rpc(
        'approve_booking',
        params: {'p_booking_id': id, 'p_reviewer_name': 'فريق المالية'},
      );
    } else if (status == PaymentReviewStatus.rejected) {
      await _client.rpc(
        'reject_booking',
        params: {
          'p_booking_id': id,
          'p_rejection_reason': 'رُفضت الدفعة من فريق المالية',
          'p_reviewer_name': 'فريق المالية',
        },
      );
    } else {
      await _client
          .from('operation_bookings')
          .update({'status': _statusToDb(status)})
          .eq('id', id);
    }
    return _fetchOne(id);
  }

  Future<FinancePayment> addNote(String id, String note) async {
    final current = await _client
        .from('operation_bookings')
        .select('notes')
        .eq('id', id)
        .single();
    final notes = (current['notes'] as List?)?.cast<String>() ?? [];
    await _client
        .from('operation_bookings')
        .update({
          'notes': [note, ...notes],
        })
        .eq('id', id);
    return _fetchOne(id);
  }

  Future<List<Map<String, dynamic>>> fetchAvailableTrips() async {
    final rows = await _client
        .from('operation_trips')
        .select('id, trip_date, departure_time, operation_routes(name)')
        .inFilter('status', ['scheduled', 'boarding'])
        .order('trip_date')
        .order('departure_time')
        .limit(50);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> reassign(String bookingId, String newTripId) {
    return _client.rpc(
      'reassign_booking',
      params: {'p_booking_id': bookingId, 'p_new_trip_id': newTripId},
    );
  }

  Future<FinancePayment> _fetchOne(String id) async {
    final row = await _client
        .from('operation_bookings')
        .select(query)
        .eq('id', id)
        .single();
    return mapBookingPayment(row);
  }

  String _statusToDb(PaymentReviewStatus status) => switch (status) {
    PaymentReviewStatus.pendingReview => 'underReview',
    PaymentReviewStatus.needsReview => 'requestReupload',
    PaymentReviewStatus.accepted => 'approved',
    PaymentReviewStatus.rejected => 'rejected',
  };
}
