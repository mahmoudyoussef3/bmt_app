import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';

/// Row → entity mapping for every wallet surface.
///
/// The wallet RPCs return one `jsonb` document per call rather than a table, so
/// there are no PostgREST row shapes to model — just decoding, in one place, so
/// that "what does `totals_by_kind` look like" is answered here and nowhere else.
///
/// Money always arrives as a Postgres `numeric`, which the client hands over as
/// `num`, `int` or (for large values) `String`. [_money] absorbs all three: a
/// balance that silently became 0 because a cast failed is the worst possible
/// bug in this module.
abstract final class WalletMapper {
  const WalletMapper._();

  static double _money(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _int(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  // ── Wallet ───────────────────────────────────────────────────────────────

  static Wallet wallet(Map<String, dynamic>? json) {
    if (json == null || json['exists'] != true) return const Wallet.empty();
    return Wallet(
      exists: true,
      id: json['id'] as String?,
      balance: _money(json['balance']),
      availableBalance: _money(json['available_balance']),
      status: WalletStatus.fromDb(_text(json['status'], 'active')),
      frozenReason: json['frozen_reason'] as String?,
      frozenAt: _date(json['frozen_at']),
      entryCount: _int(json['entry_count']),
      lifetimeCredited: _money(json['lifetime_credited']),
      lifetimeDebited: _money(json['lifetime_debited']),
      lastSeq: _int(json['last_seq']),
      headHash: json['head_hash'] as String?,
      updatedAt: _date(json['updated_at']),
    );
  }

  /// `office_wallet_set_status` returns the raw `wallets` row rather than the
  /// summary shape, so it needs its own reader.
  static Wallet walletRow(Map<String, dynamic> json) => Wallet(
    exists: true,
    id: json['id'] as String?,
    balance: _money(json['balance']),
    availableBalance: _money(json['available_balance'] ?? json['balance']),
    status: WalletStatus.fromDb(_text(json['status'], 'active')),
    frozenReason: json['frozen_reason'] as String?,
    frozenAt: _date(json['frozen_at']),
    entryCount: _int(json['entry_count']),
    lifetimeCredited: _money(json['lifetime_credited']),
    lifetimeDebited: _money(json['lifetime_debited']),
    lastSeq: _int(json['last_seq']),
    updatedAt: _date(json['updated_at']),
  );

  static WalletCustomer customer(Map<String, dynamic> json) => WalletCustomer(
    id: _text(json['id']),
    fullName: _text(json['full_name']),
    phone: _text(json['phone']),
    status: json['status'] as String?,
    createdAt: _date(json['created_at']),
  );

  static WalletPolicy policy(Map<String, dynamic>? json) {
    if (json == null) return const WalletPolicy();
    return WalletPolicy(
      maxSingleCredit: _money(json['max_single_credit']),
      maxSingleDebit: _money(json['max_single_debit']),
      maxOperatorDailyPromo: _money(json['max_operator_daily_promo']),
      requireSecondApprovalAbove: json['require_second_approval_above'] == null
          ? null
          : _money(json['require_second_approval_above']),
      timezone: _text(json['timezone'], 'Africa/Cairo'),
    );
  }

  static WalletOverview overview(Map<String, dynamic> json) => WalletOverview(
    outstandingBalance: _money(json['outstanding_balance']),
    walletCount: _int(json['wallet_count']),
    fundedWalletCount: _int(json['funded_wallet_count']),
    frozenCount: _int(json['frozen_count']),
    cashbackTotal: _money(json['cashback_total']),
    creditTotal: _money(json['credit_total']),
    debitTotal: _money(json['debit_total']),
    refundTotal: _money(json['refund_total']),
    refundWalletTotal: _money(json['refund_wallet_total']),
    pendingRefundCount: _int(json['pending_refund_count']),
    pendingRefundAmount: _money(json['pending_refund_amount']),
    policy: policy(json['policy'] as Map<String, dynamic>?),
    generatedAt: _date(json['generated_at']) ?? DateTime.now(),
  );

  static WalletDirectoryEntry directoryEntry(Map<String, dynamic> json) =>
      WalletDirectoryEntry(
        clientId: _text(json['client_id']),
        fullName: _text(json['full_name']),
        phone: _text(json['phone']),
        balance: _money(json['balance']),
        walletStatus: WalletStatus.fromDb(_text(json['wallet_status'], 'active')),
        entryCount: _int(json['entry_count']),
        pendingRefunds: _int(json['pending_refunds']),
        lastActivityAt: _date(json['last_activity_at']),
      );

  static WalletDirectoryPage directory(Map<String, dynamic> json) =>
      WalletDirectoryPage(
        total: _int(json['total']),
        rows: (json['rows'] as List? ?? const [])
            .map((row) => directoryEntry(row as Map<String, dynamic>))
            .toList(),
      );

  // ── Ledger ───────────────────────────────────────────────────────────────

  static WalletTransaction transaction(Map<String, dynamic> json) =>
      WalletTransaction(
        id: _text(json['id']),
        seq: _int(json['seq']),
        kind: WalletKind.fromDb(_text(json['kind'], 'manual_credit')),
        category: _text(json['category'], 'other'),
        source: WalletSource.fromDb(_text(json['source'], 'dashboard')),
        amount: _money(json['amount']),
        balanceBefore: _money(json['balance_before']),
        balanceAfter: _money(json['balance_after']),
        status: WalletEntryStatus.fromDb(_text(json['status'], 'posted')),
        reason: _text(json['reason']),
        notes: json['notes'] as String?,
        bookingId: json['booking_id'] as String?,
        bookingNumber: json['booking_number'] as String?,
        refundId: json['refund_id'] as String?,
        reversesTransactionId: json['reverses_transaction_id'] as String?,
        reversedBy: json['reversed_by'] as String?,
        performedBy: json['performed_by'] as String?,
        performedByName: _text(json['performed_by_name'], 'مستخدم المكتب'),
        performedByRole: json['performed_by_role'] as String?,
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        clientId: json['client_id'] as String?,
        clientName: json['client_name'] as String?,
        clientPhone: json['client_phone'] as String?,
      );

  static WalletLedgerPage ledger(Map<String, dynamic> json) => WalletLedgerPage(
    total: _int(json['total']),
    sumCredit: _money(json['sum_credit']),
    sumDebit: _money(json['sum_debit']),
    rows: (json['rows'] as List? ?? const [])
        .map((row) => transaction(row as Map<String, dynamic>))
        .toList(),
  );

  static WalletSummary summary(Map<String, dynamic> json) {
    final totals = <WalletKind, double>{};
    final raw = json['totals_by_kind'] as Map<String, dynamic>? ?? const {};
    raw.forEach((key, value) {
      totals[WalletKind.fromDb(key)] = _money(value);
    });

    return WalletSummary(
      customer: customer(json['client'] as Map<String, dynamic>? ?? const {}),
      wallet: wallet(json['wallet'] as Map<String, dynamic>?),
      totalsByKind: totals,
      pendingRefunds: (json['pending_refunds'] as List? ?? const [])
          .map((row) => refund(row as Map<String, dynamic>))
          .toList(),
      entries: (json['entries'] as List? ?? const [])
          .map((row) => transaction(row as Map<String, dynamic>))
          .toList(),
    );
  }

  static WalletChainVerification chain(Map<String, dynamic> json) =>
      WalletChainVerification(
        verified: json['verified'] == true,
        fault: json['fault'] as String?,
        divergentSeq: json['divergent_seq'] == null
            ? null
            : _int(json['divergent_seq']),
        entries: _int(json['entries']),
        ledgerBalance: _money(json['ledger_balance']),
        cachedBalance: _money(json['cached_balance']),
        headHash: json['head_hash'] as String?,
      );

  // ── Refunds ──────────────────────────────────────────────────────────────

  /// Handles both shapes this row arrives in: the flat `to_jsonb(refund_row)`
  /// an RPC returns, and the PostgREST read with `client:clients(...)` and
  /// `booking:operation_bookings(...)` embedded.
  static RefundRequest refund(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final booking = json['booking'] as Map<String, dynamic>?;

    return RefundRequest(
      id: _text(json['id']),
      clientId: json['client_id'] as String?,
      clientName: (client?['full_name'] ?? json['client_name']) as String?,
      clientPhone: (client?['phone'] ?? json['client_phone']) as String?,
      bookingId: json['booking_id'] as String?,
      bookingNumber:
          (booking?['booking_number'] ?? json['booking_number']) as String?,
      tripId: json['trip_id'] as String?,
      amount: _money(json['amount']),
      approvedAmount: json['approved_amount'] == null
          ? null
          : _money(json['approved_amount']),
      currency: _text(json['currency'], 'EGP'),
      status: RefundStatus.fromDb(_text(json['status'], 'pending')),
      category: _text(json['category'], 'other'),
      reason: _text(json['reason']),
      notes: json['notes'] as String?,
      source: _text(json['source'], 'client'),
      settlement: json['settlement_method'] == null
          ? null
          : RefundSettlement.fromDb(json['settlement_method'] as String?),
      settledAt: _date(json['settled_at']),
      walletTransactionId: json['wallet_transaction_id'] as String?,
      externalTransactionId: json['external_transaction_id'] as String?,
      batchId: json['trip_cancellation_batch_id'] as String?,
      requestedByName: json['requested_by_name'] as String?,
      reviewedByName: json['reviewed_by_name'] as String?,
      reviewedAt: _date(json['reviewed_at']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
    );
  }

  static RefundableBooking refundableBooking(Map<String, dynamic> json) =>
      RefundableBooking(
        bookingId: _text(json['booking_id']),
        bookingNumber: json['booking_number'] as String?,
        tripId: json['trip_id'] as String?,
        tripDate: _date(json['trip_date']),
        route: json['route'] as String?,
        seat: json['seat'] as String?,
        status: _text(json['status'], 'confirmed'),
        paymentMethod: (json['payment_method'] ?? json['payment_state'])
            as String?,
        paidAmount: _money(json['paid_amount']),
        refundableAmount: _money(json['refundable_amount']),
        createdAt: _date(json['created_at']),
      );

  static CancelledTripRefundTarget cancelledTrip(Map<String, dynamic> json) =>
      CancelledTripRefundTarget(
        tripId: _text(json['trip_id']),
        tripDate: _date(json['trip_date']),
        departureTime: json['departure_time'] as String?,
        routeName: json['route_name'] as String?,
        pendingBookings: _int(json['pending_bookings']),
        refundableAmount: _money(json['refundable_amount']),
      );

  static TripBatchRefundResult batchResult(Map<String, dynamic> json) =>
      TripBatchRefundResult(
        batchId: _text(json['batch_id']),
        tripId: _text(json['trip_id']),
        refunded: _int(json['refunded']),
        skipped: _int(json['skipped']),
        totalAmount: _money(json['total_amount']),
      );
}
