import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money_model.dart';
import 'finance_datasource.dart';

class SupabaseFinanceDatasource implements FinanceDatasource {
  final SupabaseClient _client;

  const SupabaseFinanceDatasource(this._client);

  static const _paidPaymentStatus = 'approved';
  
  static const _paidPaymentStatuses = [
    'submitted',
    'underReview',
    'approved',
    'rejected',
    'refunded',
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
        .limit(FinanceLedger.rowCap);
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
      
      if (r['payment_status'] != _paidPaymentStatus) continue;
      final amount = _toDouble(r['payment_amount']);
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      bookingTotal += amount;
      if (date == null) continue;
      if (!date.isBefore(todayStart)) bookingToday += amount;
      if (date.isAfter(weekStart)) bookingWeekly += amount;
      if (date.isAfter(monthStart)) bookingMonthly += amount;
    }

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
        clientName: client['full_name']?.toString() ?? 'عميل غير معروف',
        amount: _toDouble(m['amount']),
        date:
            DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: _refundStatus(m['status']?.toString()),
        reason: m['reason']?.toString() ?? '',
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
      final startDate =
          DateTime.tryParse(m['start_date']?.toString() ?? '') ?? now;
      final endDate =
          DateTime.tryParse(m['end_date']?.toString() ?? '') ??
          now.add(const Duration(days: 30));

      final tripsCount = _toInt(m['trips_count']);
      final tripsUsed = _toInt(m['trips_used']);
      final remainingRides = tripsCount > 0
          ? (tripsCount - tripsUsed).clamp(0, tripsCount)
          : endDate.difference(now).inDays.clamp(0, 9999);

      return SubscriptionRecord(
        id: m['id'].toString(),
        clientName:
            m['customer_name']?.toString() ??
            client['full_name']?.toString() ??
            'غير معروف',
        packageName: m['package_name']?.toString() ?? 'باقة',
        amount: _toDouble(m['total_price']),
        
        createdAt:
            DateTime.tryParse(m['created_at']?.toString() ?? '') ?? startDate,
        startDate: startDate,
        endDate: endDate,
        status: _subStatus(m['status']?.toString()),
        remainingRides: remainingRides,
        tripsCount: tripsCount,
        tripsUsed: tripsUsed,
      );
    }).toList();
  }

  @override
  Future<WalletFinancePosition> getWalletPosition() async {
    
    final (overview, movementRows, refundRows) = await (
      _client.rpc('office_wallet_overview'),
      _client
          .from('wallet_transactions')
          .select('created_at, kind, amount')
          .eq('status', 'posted')
          .order('created_at', ascending: false)
          .limit(FinanceLedger.rowCap),
      
      _client
          .from('refund_requests')
          .select('settled_at, approved_amount, settlement_method')
          .eq('status', 'settled')
          .order('settled_at', ascending: false)
          .limit(FinanceLedger.rowCap),
    ).wait;

    final summary = overview as Map<String, dynamic>;

    return WalletFinancePosition(
      currentLiability: _toDouble(summary['outstanding_balance']),
      movements: [
        for (final row in (movementRows as List).cast<Map<String, dynamic>>())
          if (DateTime.tryParse(row['created_at']?.toString() ?? '')
              case final date?)
            WalletMovement(
              date: date.toLocal(),
              kind: WalletMovementKind.fromDb(row['kind']?.toString() ?? ''),
              amount: _toDouble(row['amount']),
            ),
      ],
      refunds: [
        for (final row in (refundRows as List).cast<Map<String, dynamic>>())
          if (DateTime.tryParse(row['settled_at']?.toString() ?? '')
              case final date?)
            SettledRefund(
              settledAt: date.toLocal(),
              amount: _toDouble(row['approved_amount']),
              toWallet: row['settlement_method'] == 'wallet',
            ),
      ],
    );
  }

  PaymentRecord _paymentFromRow(Map<String, dynamic> r) {
    return PaymentRecord(
      id: r['id'].toString(),
      clientName: r['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: r['route']?.toString() ?? '',
      amount: _toDouble(r['payment_amount']),
      paymentMethod: _method(r['payment_method']?.toString() ?? ''),
      status: _paymentStatus(r['payment_status']?.toString() ?? ''),
      date:
          DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  FinancePaymentMethod _method(String m) => switch (m.toLowerCase()) {
    'card' || 'credit_card' || 'debit_card' => FinancePaymentMethod.card,
    'instapay' => FinancePaymentMethod.instapay,
    'wallet' ||
    'e_wallet' ||
    'vodafone' ||
    'vodafone_cash' => FinancePaymentMethod.vodafoneCash,
    _ => FinancePaymentMethod.cash,
  };

  PaymentStatus _paymentStatus(String s) => switch (s) {
    'approved' => PaymentStatus.success,
    'rejected' || 'failed' => PaymentStatus.cancelled,
    'refunded' => PaymentStatus.refunded,
    _ => PaymentStatus.pending, 
  };

  RefundStatus _refundStatus(String? s) => switch (s) {
    'approved' || 'settled' => RefundStatus.approved,
    'rejected' || 'failed' || 'cancelled' => RefundStatus.rejected,
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
