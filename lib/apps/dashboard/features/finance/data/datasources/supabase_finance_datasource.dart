import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/finance_entities.dart';
import 'finance_datasource.dart';

/// Real Supabase-backed finance datasource. Every figure is derived from
/// `operation_bookings`, `subscriptions`, `refund_requests` and the
/// `revenue_daily_view` analytics view — no mock or fabricated data.
class SupabaseFinanceDatasource implements FinanceDatasource {
  final SupabaseClient _client;

  const SupabaseFinanceDatasource(this._client);

  // Statuses that represent realised (non-cancelled) revenue.
  static const _nonRevenueStatuses = ['rejected', 'cancelled'];
  // Booking statuses that belong to the receipt-review workflow.
  static const _receiptStatuses = [
    'paymentUploaded',
    'underReview',
    'requestReupload',
    'approved',
    'rejected',
  ];

  @override
  Future<List<PaymentRecord>> getPayments() async {
    final rows = await _client
        .from('operation_bookings')
        .select(
          'id, passenger_name, route, payment_amount, payment_method, status, created_at',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _paymentFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RevenueMetrics> getRevenueMetrics() async {
    final rows = await _client
        .from('operation_bookings')
        .select('payment_amount, status, created_at');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = now.subtract(const Duration(days: 30));

    double today = 0, weekly = 0, monthly = 0, total = 0;
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      if (_nonRevenueStatuses.contains(r['status'])) continue;
      final amount =
          double.tryParse(r['payment_amount']?.toString() ?? '0') ?? 0;
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      total += amount;
      if (date == null) continue;
      if (!date.isBefore(todayStart)) today += amount;
      if (date.isAfter(weekStart)) weekly += amount;
      if (date.isAfter(monthStart)) monthly += amount;
    }

    final subs = await _client.from('subscriptions').select('status');
    final activeSubs = (subs as List)
        .where((s) => (s as Map)['status'] == 'active')
        .length;

    return RevenueMetrics(
      todayRevenue: today,
      weeklyRevenue: weekly,
      monthlyRevenue: monthly,
      activeSubscriptions: activeSubs,
      totalBookingsRevenue: total,
    );
  }

  @override
  Future<List<RevenueTrendPoint>> getRevenueTrend() async {
    final rows = await _client
        .from('revenue_daily_view')
        .select('report_date, total_bookings_revenue, total_bookings')
        .order('report_date', ascending: true)
        .limit(60);
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      return RevenueTrendPoint(
        date:
            DateTime.tryParse(m['report_date']?.toString() ?? '') ??
            DateTime.now(),
        amount:
            double.tryParse(m['total_bookings_revenue']?.toString() ?? '0') ??
            0,
        bookings: int.tryParse(m['total_bookings']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async {
    final rows = await _client
        .from('operation_bookings')
        .select(
          'id, passenger_name, route, payment_amount, status, created_at, payment_receipt_url, payment_details, notes, timeline',
        )
        .inFilter('status', _receiptStatuses)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _receiptFromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RefundRequest>> getRefundRequests() async {
    final response = await _client
        .from('refund_requests')
        .select('''
      *,
      client:clients(full_name)
    ''')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final m = json as Map<String, dynamic>;
      final client = m['client'] as Map<String, dynamic>? ?? {};
      final statusStr = m['status']?.toString();
      final mappedStatus = switch (statusStr) {
        'approved' => RefundStatus.approved,
        'rejected' => RefundStatus.rejected,
        _ => RefundStatus.pending,
      };
      return RefundRequest(
        id: m['id'].toString(),
        transactionId: m['booking_id']?.toString() ?? '',
        clientName: client['full_name']?.toString() ?? 'عميل غير معروف',
        amount: double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0,
        date:
            DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: mappedStatus,
        reason: m['reason']?.toString() ?? '',
        history: const [],
      );
    }).toList();
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    final rows = await _client
        .from('subscriptions')
        .select('''
      *,
      client:clients(full_name)
    ''')
        .order('created_at', ascending: false);

    return (rows as List).map((json) {
      final m = json as Map<String, dynamic>;
      final client = m['client'] as Map<String, dynamic>? ?? {};
      final statusStr = m['status']?.toString();
      final mappedStatus = switch (statusStr) {
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        _ => SubscriptionStatus.active,
      };
      final now = DateTime.now();
      final endDate =
          DateTime.tryParse(m['end_date']?.toString() ?? '') ??
          now.add(const Duration(days: 30));
      // No per-ride field exists in `subscriptions`; surface remaining days
      // (real, derived) instead of fabricating a ride count.
      final remainingDays = endDate.difference(now).inDays;
      return SubscriptionRecord(
        id: m['id'].toString(),
        clientName:
            m['customer_name']?.toString() ??
            client['full_name']?.toString() ??
            'غير معروف',
        packageName: m['package_name']?.toString() ?? 'باقة',
        amount: double.tryParse(m['total_price']?.toString() ?? '0') ?? 0.0,
        startDate: DateTime.tryParse(m['start_date']?.toString() ?? '') ?? now,
        endDate: endDate,
        status: mappedStatus,
        remainingRides: remainingDays < 0 ? 0 : remainingDays,
      );
    }).toList();
  }

  @override
  Future<void> reviewReceipt(
    String id,
    ReceiptReviewStatus action, {
    String? notes,
  }) async {
    final dbStatus = switch (action) {
      ReceiptReviewStatus.accepted => 'approved',
      ReceiptReviewStatus.rejected => 'rejected',
      ReceiptReviewStatus.reuploadRequested => 'requestReupload',
      ReceiptReviewStatus.pending => 'underReview',
    };
    final update = <String, dynamic>{'status': dbStatus};
    if (notes != null && notes.isNotEmpty) {
      final current = await _client
          .from('operation_bookings')
          .select('notes')
          .eq('id', id)
          .single();
      final currentNotes = (current['notes'] as List?)?.cast<dynamic>() ?? [];
      update['notes'] = [notes, ...currentNotes];
    }
    await _client.from('operation_bookings').update(update).eq('id', id);
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    final dbStatus = action == RefundStatus.approved ? 'approved' : 'rejected';
    await _client
        .from('refund_requests')
        .update({
          'status': dbStatus,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> cancelSubscription(String id) async {
    await _client
        .from('subscriptions')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  // ----- mapping helpers -----

  PaymentRecord _paymentFromRow(Map<String, dynamic> r) {
    return PaymentRecord(
      id: r['id'].toString(),
      clientName: r['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: r['route']?.toString() ?? '',
      amount: double.tryParse(r['payment_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: _methodFromDb(r['payment_method']?.toString() ?? ''),
      status: _paymentStatusFromDb(r['status']?.toString() ?? ''),
      date:
          DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  ReceiptReview _receiptFromRow(Map<String, dynamic> r) {
    final details = r['payment_details'] as Map<String, dynamic>? ?? {};
    final timeline = (r['timeline'] as List?) ?? const [];
    return ReceiptReview(
      id: r['id'].toString(),
      transactionId:
          details['reference']?.toString() ??
          r['id'].toString().substring(0, 8).toUpperCase(),
      clientName: r['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: r['route']?.toString() ?? '',
      amount: double.tryParse(r['payment_amount']?.toString() ?? '0') ?? 0.0,
      date:
          DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
      receiptUrl: r['payment_receipt_url']?.toString() ?? '',
      status: _receiptStatusFromDb(r['status']?.toString() ?? ''),
      notes: (r['notes'] as List?)?.cast<dynamic>().join('\n'),
      history: timeline
          .map(
            (e) => '${(e as Map)['action'] ?? ''} — ${e['actor'] ?? ''}'.trim(),
          )
          .where((e) => e.isNotEmpty && e != '—')
          .cast<String>()
          .toList(),
    );
  }

  FinancePaymentMethod _methodFromDb(String m) => switch (m.toLowerCase()) {
    'card' || 'credit_card' || 'debit_card' => FinancePaymentMethod.card,
    'instapay' => FinancePaymentMethod.instapay,
    'wallet' ||
    'e_wallet' ||
    'vodafone' ||
    'vodafone_cash' => FinancePaymentMethod.vodafoneCash,
    _ => FinancePaymentMethod.cash,
  };

  PaymentStatus _paymentStatusFromDb(String s) => switch (s) {
    'confirmed' || 'approved' || 'completed' || 'paid' => PaymentStatus.success,
    'cancelled' || 'rejected' => PaymentStatus.cancelled,
    'refunded' => PaymentStatus.refunded,
    _ => PaymentStatus.pending,
  };

  ReceiptReviewStatus _receiptStatusFromDb(String s) => switch (s) {
    'approved' => ReceiptReviewStatus.accepted,
    'rejected' => ReceiptReviewStatus.rejected,
    'requestReupload' => ReceiptReviewStatus.reuploadRequested,
    _ => ReceiptReviewStatus.pending,
  };
}
