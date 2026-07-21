import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/finance_entities.dart';
import 'finance_datasource.dart';

class SupabaseFinanceDatasource implements FinanceDatasource {
  final SupabaseClient _client;

  const SupabaseFinanceDatasource(this._client);

  // Realised revenue = payments a client actually made AND finance verified.
  static const _paidPaymentStatus = 'approved';
  // A "payment" only exists once the client submits it; drafts and unpaid
  // credit-card intents (payment_status = 'pending') are not payments yet.
  static const _paidPaymentStatuses = [
    'submitted',
    'underReview',
    'approved',
    'rejected',
    'refunded',
  ];
  // The review queue keys off the decoupled payment_status column, never the
  // booking lifecycle status (draft/reserved/confirmed/…).
  static const _reviewPaymentStatuses = [
    'submitted',
    'underReview',
    'approved',
    'rejected',
  ];

  @override
  Future<List<PaymentRecord>> getPayments() async {
    final rows = await _client
        .from('operation_bookings')
        .select(
          'id, passenger_name, route, payment_amount, payment_method, '
          'payment_status, created_at',
        )
        .inFilter('payment_status', _paidPaymentStatuses)
        .order('created_at', ascending: false)
        .limit(500);
    return rows.map((r) => _paymentFromRow(r)).toList();
  }

  @override
  Future<RevenueMetrics> getRevenueMetrics() async {
    final bookingRows = await _client
        .from('operation_bookings')
        .select('payment_amount, payment_status, created_at');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = now.subtract(const Duration(days: 30));

    double bookingToday = 0,
        bookingWeekly = 0,
        bookingMonthly = 0,
        bookingTotal = 0;
    for (final r in (bookingRows as List).cast<Map<String, dynamic>>()) {
      // Only verified payments count as realised revenue.
      if (r['payment_status'] != _paidPaymentStatus) continue;
      final amount = _toDouble(r['payment_amount']);
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      bookingTotal += amount;
      if (date == null) continue;
      if (!date.isBefore(todayStart)) bookingToday += amount;
      if (date.isAfter(weekStart)) bookingWeekly += amount;
      if (date.isAfter(monthStart)) bookingMonthly += amount;
    }

    // Include subscription revenue in totals (subscriptions with active/
    // expired status where total_price > 0 represent realised revenue).
    final subRows = await _client
        .from('subscriptions')
        .select('status, total_price, created_at');

    double subToday = 0, subWeekly = 0, subMonthly = 0, subTotal = 0;
    int activeSubs = 0;
    for (final r in (subRows as List).cast<Map<String, dynamic>>()) {
      final status = r['status']?.toString() ?? '';
      if (status == 'cancelled' || status == 'pending_payment') continue;
      if (status == 'active') activeSubs++;
      final amount = _toDouble(r['total_price']);
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      subTotal += amount;
      if (date == null) continue;
      if (!date.isBefore(todayStart)) subToday += amount;
      if (date.isAfter(weekStart)) subWeekly += amount;
      if (date.isAfter(monthStart)) subMonthly += amount;
    }

    return RevenueMetrics(
      todayRevenue: bookingToday + subToday,
      weeklyRevenue: bookingWeekly + subWeekly,
      monthlyRevenue: bookingMonthly + subMonthly,
      activeSubscriptions: activeSubs,
      totalBookingsRevenue: bookingTotal,
      totalSubscriptionsRevenue: subTotal,
    );
  }

  @override
  Future<List<RevenueTrendPoint>> getRevenueTrend() async {
    try {
      final rows = await _client
          .from('revenue_daily_view')
          .select('report_date, total_bookings_revenue, total_bookings')
          .order('report_date', ascending: true)
          .limit(60);
      return (rows as List).map((r) {
        final m = r as Map<String, dynamic>;
        return RevenueTrendPoint(
          date: DateTime.tryParse(m['report_date']?.toString() ?? '') ??
              DateTime.now(),
          amount: _toDouble(m['total_bookings_revenue']),
          bookings: _toInt(m['total_bookings']),
        );
      }).toList();
    } catch (_) {
      // View may not exist yet (migration pending). Fall back to aggregating
      // operation_bookings in-memory for the last 30 days.
      final rows = await _client
          .from('operation_bookings')
          .select('created_at, payment_amount, payment_status')
          .order('created_at', ascending: true);

      final byDay = <String, _DayAgg>{};
      for (final r in (rows as List).cast<Map<String, dynamic>>()) {
        final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
        if (date == null) continue;
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final agg = byDay.putIfAbsent(key, () => _DayAgg());
        agg.bookings++;
        if (r['payment_status'] == _paidPaymentStatus) {
          agg.revenue += _toDouble(r['payment_amount']);
        }
      }
      final sortedKeys = byDay.keys.toList()..sort();
      return sortedKeys.map((k) {
        final agg = byDay[k]!;
        return RevenueTrendPoint(
          date: DateTime.parse(k),
          amount: agg.revenue,
          bookings: agg.bookings,
        );
      }).toList();
    }
  }

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async {
    final rows = await _client
        .from('operation_bookings')
        .select(
          'id, passenger_name, route, payment_amount, payment_status, '
          'created_at, payment_receipt_url, payment_details, notes, timeline',
        )
        .inFilter('payment_status', _reviewPaymentStatuses)
        .order('created_at', ascending: false);
    return rows.map((r) => _receiptFromRow(r)).toList();
  }

  @override
  Future<List<RefundRequest>> getRefundRequests() async {
    final response = await _client
        .from('refund_requests')
        .select('*, client:clients(full_name)')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final m = json as Map<String, dynamic>;
      final client = m['client'] as Map<String, dynamic>? ?? {};
      return RefundRequest(
        id: m['id'].toString(),
        transactionId: m['booking_id']?.toString() ?? '',
        clientName:
            client['full_name']?.toString() ?? 'عميل غير معروف',
        amount: _toDouble(m['amount']),
        date: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: _refundStatus(m['status']?.toString()),
        reason: m['reason']?.toString() ?? '',
        history: const [],
      );
    }).toList();
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    final rows = await _client
        .from('subscriptions')
        .select('*, client:clients(full_name)')
        .order('created_at', ascending: false);

    return (rows as List).map((json) {
      final m = json as Map<String, dynamic>;
      final client = m['client'] as Map<String, dynamic>? ?? {};
      final now = DateTime.now();
      final endDate = DateTime.tryParse(m['end_date']?.toString() ?? '') ??
          now.add(const Duration(days: 30));

      // Real ride balance: trips_count − trips_used.
      // Falls back to remaining days only when trips_count is 0 (legacy rows).
      final tripsCount = _toInt(m['trips_count']);
      final tripsUsed = _toInt(m['trips_used']);
      final remainingRides = tripsCount > 0
          ? (tripsCount - tripsUsed).clamp(0, tripsCount)
          : endDate.difference(now).inDays.clamp(0, 9999);

      return SubscriptionRecord(
        id: m['id'].toString(),
        clientName: m['customer_name']?.toString() ??
            client['full_name']?.toString() ??
            'غير معروف',
        packageName: m['package_name']?.toString() ?? 'باقة',
        amount: _toDouble(m['total_price']),
        startDate:
            DateTime.tryParse(m['start_date']?.toString() ?? '') ?? now,
        endDate: endDate,
        status: _subStatus(m['status']?.toString()),
        remainingRides: remainingRides,
        tripsCount: tripsCount,
        tripsUsed: tripsUsed,
      );
    }).toList();
  }

  @override
  Future<void> reviewReceipt(
    String id,
    ReceiptReviewStatus action, {
    String? notes,
  }) async {
    // Route decisions through the same audited RPCs the payment-verification
    // workflow uses. A raw status write would violate valid_booking_status,
    // skip the seat/subscription/notification side effects, and leave
    // booking_payments out of sync.
    final note = notes?.trim() ?? '';
    switch (action) {
      case ReceiptReviewStatus.accepted:
        await _client.rpc(
          'office_approve_payment',
          params: {'p_booking_id': id, 'p_note': note},
        );
      case ReceiptReviewStatus.rejected:
        await _client.rpc(
          'office_reject_payment',
          params: {
            'p_booking_id': id,
            'p_reason': note.isEmpty ? 'رُفض إثبات الدفع' : note,
          },
        );
      case ReceiptReviewStatus.reuploadRequested:
        await _client.rpc(
          'office_request_payment_review',
          params: {'p_booking_id': id, 'p_note': note},
        );
      case ReceiptReviewStatus.pending:
        break; // Inbound state, not an action.
    }
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    final dbStatus =
        action == RefundStatus.approved ? 'approved' : 'rejected';
    await _client.from('refund_requests').update({
      'status': dbStatus,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> cancelSubscription(String id) async {
    await _client
        .from('subscriptions')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────────

  PaymentRecord _paymentFromRow(Map<String, dynamic> r) {
    return PaymentRecord(
      id: r['id'].toString(),
      clientName: r['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: r['route']?.toString() ?? '',
      amount: _toDouble(r['payment_amount']),
      paymentMethod: _method(r['payment_method']?.toString() ?? ''),
      status: _paymentStatus(r['payment_status']?.toString() ?? ''),
      date: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  ReceiptReview _receiptFromRow(Map<String, dynamic> r) {
    final details = r['payment_details'] as Map<String, dynamic>? ?? {};
    final timeline = (r['timeline'] as List?) ?? const [];
    return ReceiptReview(
      id: r['id'].toString(),
      transactionId: details['reference']?.toString() ??
          r['id'].toString().substring(0, 8).toUpperCase(),
      clientName: r['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: r['route']?.toString() ?? '',
      amount: _toDouble(r['payment_amount']),
      date: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
      receiptUrl: r['payment_receipt_url']?.toString() ?? '',
      status: _receiptStatus(r['payment_status']?.toString() ?? ''),
      notes: (r['notes'] as List?)?.cast<dynamic>().join('\n'),
      history: timeline
          .map((e) =>
              '${(e as Map)['action'] ?? ''} — ${e['actor'] ?? ''}'.trim())
          .where((e) => e.isNotEmpty && e != '—')
          .cast<String>()
          .toList(),
    );
  }

  FinancePaymentMethod _method(String m) => switch (m.toLowerCase()) {
        'card' || 'credit_card' || 'debit_card' => FinancePaymentMethod.card,
        'instapay' => FinancePaymentMethod.instapay,
        'wallet' ||
        'e_wallet' ||
        'vodafone' ||
        'vodafone_cash' =>
          FinancePaymentMethod.vodafoneCash,
        _ => FinancePaymentMethod.cash,
      };

  // Maps the decoupled payment_status vocabulary
  // (pending/submitted/underReview/approved/rejected/refunded/failed).
  PaymentStatus _paymentStatus(String s) => switch (s) {
        'approved' => PaymentStatus.success,
        'rejected' || 'failed' => PaymentStatus.cancelled,
        'refunded' => PaymentStatus.refunded,
        _ => PaymentStatus.pending, // pending / submitted / underReview
      };

  ReceiptReviewStatus _receiptStatus(String s) => switch (s) {
        'approved' => ReceiptReviewStatus.accepted,
        'rejected' => ReceiptReviewStatus.rejected,
        'underReview' => ReceiptReviewStatus.reuploadRequested,
        _ => ReceiptReviewStatus.pending, // submitted
      };

  RefundStatus _refundStatus(String? s) => switch (s) {
        'approved' => RefundStatus.approved,
        'rejected' => RefundStatus.rejected,
        _ => RefundStatus.pending,
      };

  SubscriptionStatus _subStatus(String? s) => switch (s) {
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        'pending_payment' || 'paused' => SubscriptionStatus.pendingPayment,
        _ => SubscriptionStatus.active,
      };

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class _DayAgg {
  double revenue = 0;
  int bookings = 0;
}
