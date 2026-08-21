import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money_model.dart';
import '../mappers/finance_row_mapper.dart';
import 'finance_datasource.dart';

/// Reads the office's money.
///
/// Every query here is office-scoped by RLS (`office_id = current_office_id()`)
/// and never by a client-side filter, so a figure on the finance screen cannot
/// be widened by editing a request. What each row *means* is
/// [FinanceRowMapper]'s job; this file only decides which rows to ask for.
class SupabaseFinanceDatasource implements FinanceDatasource {
  final SupabaseClient _client;

  const SupabaseFinanceDatasource(this._client);

  /// The one payment state that means the office has the money.
  static const _paidPaymentStatus = 'approved';

  /// Columns the ledger and the transaction detail actually read. Selecting the
  /// row wholesale pulls four `jsonb` blobs — `customer_profile`,
  /// `trip_details`, `payment_details`, `timeline` — per booking, which is most
  /// of the payload and none of the screen.
  static const _bookingColumns =
      'id, booking_number, passenger_name, phone, route, '
      'pickup_point_name, dropoff_point_name, trip_date, '
      'payment_amount, payment_method, payment_status, payment_receipt_url, '
      'payment_rejection_reason, status, created_at';

  static const _subscriptionColumns =
      'id, customer_name, package_name, total_price, paid_amount, '
      'remaining_amount, status, payment_review_status, '
      'trips_count, trips_used, start_date, end_date, created_at, '
      'client:clients(full_name)';

  static const _refundColumns =
      'id, booking_id, amount, status, reason, created_at, '
      'client:clients(full_name)';

  /// Every money movement on a booking, whatever state it is in.
  ///
  /// The list is deliberately **unfiltered by payment state**. An earlier
  /// revision selected only `submitted / underReview / approved / rejected /
  /// refunded`, which silently dropped every `pending` and `cancelled` row — on
  /// a live office that was the single largest category of uncollected fare, so
  /// "قيد التحصيل" reported a fraction of what was actually owed. A ledger that
  /// decides in the query which money is worth knowing about is not a ledger.
  @override
  Future<List<PaymentRecord>> getPayments() async {
    final rows = await _client
        .from('operation_bookings')
        .select(_bookingColumns)
        .order('created_at', ascending: false)
        .limit(FinanceLedger.rowCap);
    return [for (final row in rows) FinanceRowMapper.payment(row)];
  }

  /// Office-wide totals for the home and executive overviews.
  ///
  /// Deliberately **uncapped**, unlike every list query in the module: these are
  /// sums, and a sum over the newest three thousand rows presented as the total
  /// is precisely the silent truncation `DashboardQueryCaps` exists to forbid.
  /// The cost is bounded instead by asking for three narrow columns.
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
      final amount = FinanceRowMapper.toDouble(r['payment_amount']);
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      bookingTotal += amount;
      if (date == null) continue;
      if (!date.isBefore(todayStart)) bookingToday += amount;
      if (date.isAfter(weekStart)) bookingWeekly += amount;
      if (date.isAfter(monthStart)) bookingMonthly += amount;
    }

    final subRows = await _client
        .from('subscriptions')
        .select('status, total_price, paid_amount, created_at');

    double subToday = 0, subWeekly = 0, subMonthly = 0, subTotal = 0;
    int activeSubs = 0;
    for (final r in (subRows as List).cast<Map<String, dynamic>>()) {
      final status = r['status']?.toString() ?? '';
      if (status == 'cancelled' || status == 'pending_payment') continue;
      if (status == 'active') activeSubs++;

      // What arrived, not what was invoiced. A package can go active on a
      // deposit, and `total_price` counts the unpaid balance as revenue.
      final amount = FinanceRowMapper.collectedSubscriptionAmount(r);
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
    final rows = await _client
        .from('refund_requests')
        .select(_refundColumns)
        .order('created_at', ascending: false)
        .limit(FinanceLedger.rowCap);
    return [for (final row in rows) FinanceRowMapper.refund(row)];
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    final rows = await _client
        .from('subscriptions')
        .select(_subscriptionColumns)
        .order('created_at', ascending: false)
        .limit(FinanceLedger.rowCap);

    final now = DateTime.now();
    return [
      for (final row in rows) FinanceRowMapper.subscription(row, now: now),
    ];
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
      currentLiability: FinanceRowMapper.toDouble(
        summary['outstanding_balance'],
      ),
      movements: [
        for (final row in (movementRows as List).cast<Map<String, dynamic>>())
          if (DateTime.tryParse(row['created_at']?.toString() ?? '')
              case final date?)
            WalletMovement(
              date: date.toLocal(),
              kind: WalletMovementKind.fromDb(row['kind']?.toString() ?? ''),
              amount: FinanceRowMapper.toDouble(row['amount']),
            ),
      ],
      refunds: [
        for (final row in (refundRows as List).cast<Map<String, dynamic>>())
          if (DateTime.tryParse(row['settled_at']?.toString() ?? '')
              case final date?)
            SettledRefund(
              settledAt: date.toLocal(),
              amount: FinanceRowMapper.toDouble(row['approved_amount']),
              toWallet: row['settlement_method'] == 'wallet',
            ),
      ],
    );
  }
}
