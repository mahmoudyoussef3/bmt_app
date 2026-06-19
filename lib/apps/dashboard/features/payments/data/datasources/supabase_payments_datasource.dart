import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/finance_payment.dart';
import '../models/finance_payment_model.dart';
import 'payments_datasource.dart';

class SupabasePaymentsDatasource implements PaymentsDatasource {
  const SupabasePaymentsDatasource(this._client);

  final SupabaseClient _client;

  static const _query = '''
    id, passenger_name, phone, status, created_at,
    payment_details, payment_receipt_url, notes, timeline,
    trip:operation_trips(trip_date, departure_time, route:operation_routes(name))
  ''';

  static const _statuses = [
    'paymentUploaded',
    'underReview',
    'requestReupload',
    'approved',
    'rejected',
  ];

  @override
  Future<List<FinancePayment>> fetchPayments() async {
    final rows = await _client
        .from('operation_bookings')
        .select(_query)
        .inFilter('status', _statuses)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  ) async {
    await _client
        .from('operation_bookings')
        .update({'status': _statusToDb(status)})
        .eq('id', paymentId);
    final row = await _client
        .from('operation_bookings')
        .select(_query)
        .eq('id', paymentId)
        .single();
    return _fromRow(row);
  }

  @override
  Future<FinancePayment> addNote(String paymentId, String note) async {
    final current = await _client
        .from('operation_bookings')
        .select('notes')
        .eq('id', paymentId)
        .single();
    final currentNotes = (current['notes'] as List?)?.cast<String>() ?? [];
    await _client
        .from('operation_bookings')
        .update({'notes': [note, ...currentNotes]})
        .eq('id', paymentId);
    final row = await _client
        .from('operation_bookings')
        .select(_query)
        .eq('id', paymentId)
        .single();
    return _fromRow(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableTrips() async {
    final rows = await _client
        .from('operation_trips')
        .select('id, trip_date, departure_time, operation_routes(name)')
        .inFilter('status', ['scheduled', 'boarding'])
        .order('trip_date')
        .order('departure_time')
        .limit(50);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> reassignBooking(String bookingId, String newTripId) async {
    await _client.rpc('reassign_booking', params: {
      'p_booking_id': bookingId,
      'p_new_trip_id': newTripId,
    });
  }

  FinancePaymentModel _fromRow(Map<String, dynamic> r) {
    final details = r['payment_details'] as Map<String, dynamic>? ?? {};
    final trip = r['trip'] as Map<String, dynamic>? ?? {};
    final route = trip['route'] as Map<String, dynamic>? ?? {};
    final status = _statusFromDb(r['status'] as String? ?? '');
    final method = _methodFromDb(details['method'] as String? ?? '');
    final notes = (r['notes'] as List?)?.cast<String>() ?? [];
    final timeline = (r['timeline'] as List?) ?? [];
    final tripDate = trip['trip_date'] as String? ?? '';
    final depTime = trip['departure_time'] as String? ?? '';
    final routeName = route['name'] as String? ?? '';
    final amount = details['amount']?.toString() ?? '0';

    final receiptUrl = r['payment_receipt_url'] as String?;
    return FinancePaymentModel(
      id: r['id'] as String,
      userName: r['passenger_name'] as String? ?? '',
      amount: '$amount ج.م',
      method: method,
      paidAt: _formatDate(r['created_at'] as String?),
      status: status,
      user: '${r['passenger_name'] ?? ''} - ${r['phone'] ?? ''}',
      trip: routeName.isNotEmpty
          ? '$routeName  $tripDate  $depTime'
          : tripDate,
      packageName: 'رحلة مفردة',
      referenceNumber: details['reference'] as String? ??
          (r['id'] as String).substring(0, 8).toUpperCase(),
      receiptLabel: _receiptLabel(method),
      receiptMeta: _receiptMeta(receiptUrl),
      receiptUrl: receiptUrl,
      notes: notes,
      history: timeline
          .map(
            (e) => PaymentHistoryItem(
              title: (e['action'] ?? e['title'] ?? '').toString(),
              time: (e['timestamp'] ?? e['time'] ?? '').toString(),
              description: (e['actor'] ?? e['description'] ?? '').toString(),
            ),
          )
          .toList(),
    );
  }

  PaymentReviewStatus _statusFromDb(String s) => switch (s) {
    'paymentUploaded' || 'underReview' => PaymentReviewStatus.pendingReview,
    'requestReupload'                  => PaymentReviewStatus.needsReview,
    'approved' || 'confirmed'          => PaymentReviewStatus.accepted,
    'rejected'                         => PaymentReviewStatus.rejected,
    _                                  => PaymentReviewStatus.pendingReview,
  };

  String _statusToDb(PaymentReviewStatus s) => switch (s) {
    PaymentReviewStatus.pendingReview => 'underReview',
    PaymentReviewStatus.needsReview   => 'requestReupload',
    PaymentReviewStatus.accepted      => 'approved',
    PaymentReviewStatus.rejected      => 'rejected',
  };

  FinancePaymentMethod _methodFromDb(String m) => switch (m.toLowerCase()) {
    'card' || 'credit_card' || 'debit_card' => FinancePaymentMethod.card,
    'wallet' || 'e_wallet'                  => FinancePaymentMethod.wallet,
    'bank_transfer' || 'banktransfer'       => FinancePaymentMethod.bankTransfer,
    'cash'                                  => FinancePaymentMethod.cash,
    _                                       => FinancePaymentMethod.bankTransfer,
  };

  String _receiptLabel(FinancePaymentMethod m) => switch (m) {
    FinancePaymentMethod.card         => 'إيصال دفع بطاقة',
    FinancePaymentMethod.wallet       => 'لقطة شاشة محفظة',
    FinancePaymentMethod.bankTransfer => 'إيصال تحويل بنكي',
    FinancePaymentMethod.cash         => 'إيصال نقدي',
  };

  String _receiptMeta(String? url) =>
      url != null && url.isNotEmpty ? 'صورة إيصال مرفوعة' : 'لم يتم رفع إيصال';

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'اليوم ${_time(dt)}';
      if (diff.inDays == 1) return 'أمس ${_time(dt)}';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'ص' : 'م';
    return '$h:$m $ampm';
  }
}
