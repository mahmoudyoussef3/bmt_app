/// Money that needs a decision, and where that decision is made.
///
/// ## Why this is not a contradiction of the module's charter
///
/// Finance reports; it does not decide. That rule is about *authority* — there
/// is no approve button here and there must never be one. It was never a rule
/// about *silence*. An owner who has to read a 3,000-row ledger to discover
/// that eleven receipts have been sitting unreviewed for a week is being served
/// a database, not a finance screen.
///
/// So this file derives the queues from data the module already holds and hands
/// each one the route of the module that owns the decision. Finance says "eight
/// receipts, 4,310 ج.م, decide them in الحجوزات"; الحجوزات decides them.
///
/// ## Scope: the whole book, not the window
///
/// Every figure elsewhere in the module is scoped by the period bar. These are
/// deliberately **not**. A receipt uploaded forty days ago still needs a
/// decision today, and a period filter that hides it turns the one actionable
/// panel on the screen into a way to lose work. The panel says so in words.
library;

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';

import 'finance_entities.dart';
import 'finance_money_model.dart';

/// How loudly a queue asks. Three levels, because a fourth is a colour nobody
/// can rank against the others.
enum FinanceAttentionSeverity {
  /// Money is exposed right now and someone must act today.
  urgent,

  /// Money is drifting; act this week.
  warning,

  /// Worth knowing, nothing is at risk.
  info,
}

/// The queues Finance can derive honestly from what it loads.
///
/// Each one is a real, countable set of rows — never a heuristic, never a
/// "score". If a category cannot be counted from data on hand it does not
/// appear here, however useful it would be.
enum FinanceAttentionKind {
  /// A receipt is uploaded and nobody has accepted or refused it.
  receiptsAwaitingReview,

  /// A customer has asked for money back and no decision has been recorded.
  refundRequestsPending,

  /// The office took the money and the seat was then cancelled. It is holding
  /// cash against a service it will not deliver.
  collectedOnCancelledSeat,

  /// A live seat whose fare has not arrived.
  unpaidLiveBookings,

  /// A package that went active on a part payment and still owes a balance.
  subscriptionsPartPaid,

  /// A package sold but not paid for at all.
  subscriptionsAwaitingPayment,

  /// The three-statement control identity does not balance. Nothing on the
  /// screen can be trusted until it does, so it outranks everything.
  identityBroken;

  /// Where the decision is actually made. `null` means it is made here —
  /// which, for the one entry that has no route, means "stop and check the
  /// data before you rely on any of this".
  String? get route => switch (this) {
    FinanceAttentionKind.receiptsAwaitingReview =>
      DashboardRoutes.paymentVerification,
    FinanceAttentionKind.refundRequestsPending => DashboardRoutes.wallet,
    FinanceAttentionKind.collectedOnCancelledSeat => DashboardRoutes.bookings,
    FinanceAttentionKind.unpaidLiveBookings => DashboardRoutes.bookings,
    FinanceAttentionKind.subscriptionsPartPaid =>
      DashboardRoutes.subscriptions,
    FinanceAttentionKind.subscriptionsAwaitingPayment =>
      DashboardRoutes.subscriptions,
    FinanceAttentionKind.identityBroken => null,
  };

  /// What the queue is called.
  String get title => switch (this) {
    FinanceAttentionKind.receiptsAwaitingReview => 'إيصالات بانتظار المراجعة',
    FinanceAttentionKind.refundRequestsPending => 'طلبات استرداد بلا قرار',
    FinanceAttentionKind.collectedOnCancelledSeat =>
      'مبالغ محصّلة على حجوزات ملغاة',
    FinanceAttentionKind.unpaidLiveBookings => 'حجوزات قائمة لم تُحصّل',
    FinanceAttentionKind.subscriptionsPartPaid => 'اشتراكات محصّلة جزئياً',
    FinanceAttentionKind.subscriptionsAwaitingPayment =>
      'اشتراكات بانتظار الدفع',
    FinanceAttentionKind.identityBroken => 'معادلة الضبط غير متوازنة',
  };

  /// What clearing it means, in the imperative. An owner should never have to
  /// infer the next move from a count.
  String get action => switch (this) {
    FinanceAttentionKind.receiptsAwaitingReview =>
      'راجع الإيصال واقبله أو ارفضه',
    FinanceAttentionKind.refundRequestsPending =>
      'اعتمد المبلغ أو ارفض الطلب',
    FinanceAttentionKind.collectedOnCancelledSeat =>
      'أعد المبلغ للعميل أو انقله لحجز آخر',
    FinanceAttentionKind.unpaidLiveBookings =>
      'تابع تحصيل الأجرة قبل موعد الرحلة',
    FinanceAttentionKind.subscriptionsPartPaid => 'حصّل باقي قيمة الباقة',
    FinanceAttentionKind.subscriptionsAwaitingPayment =>
      'تابع تحصيل قيمة الباقة',
    FinanceAttentionKind.identityBroken =>
      'راجع بيانات المحفظة والمرتجعات قبل اعتماد الأرقام',
  };

  /// The noun the count is measured in.
  String get unit => switch (this) {
    FinanceAttentionKind.receiptsAwaitingReview => 'إيصال',
    FinanceAttentionKind.refundRequestsPending => 'طلب',
    FinanceAttentionKind.collectedOnCancelledSeat => 'حجز',
    FinanceAttentionKind.unpaidLiveBookings => 'حجز',
    FinanceAttentionKind.subscriptionsPartPaid => 'اشتراك',
    FinanceAttentionKind.subscriptionsAwaitingPayment => 'اشتراك',
    FinanceAttentionKind.identityBroken => 'فارق',
  };

  FinanceAttentionSeverity get severity => switch (this) {
    FinanceAttentionKind.identityBroken ||
    FinanceAttentionKind.receiptsAwaitingReview ||
    FinanceAttentionKind.refundRequestsPending ||
    FinanceAttentionKind.collectedOnCancelledSeat =>
      FinanceAttentionSeverity.urgent,
    FinanceAttentionKind.unpaidLiveBookings ||
    FinanceAttentionKind.subscriptionsPartPaid ||
    FinanceAttentionKind.subscriptionsAwaitingPayment =>
      FinanceAttentionSeverity.warning,
  };
}

/// One queue: how many, how much, and — for the money already in hand — whether
/// the amount is exposure or merely expectation.
class FinanceAttentionItem {
  final FinanceAttentionKind kind;
  final int count;

  /// The money the queue represents. For [FinanceAttentionKind.identityBroken]
  /// this is the size of the gap, not a sum of rows.
  final double amount;

  const FinanceAttentionItem({
    required this.kind,
    required this.count,
    required this.amount,
  });

  FinanceAttentionSeverity get severity => kind.severity;
}

/// Everything waiting on the owner, ordered so the top row is the one to do
/// first.
class FinanceAttention {
  final List<FinanceAttentionItem> items;

  const FinanceAttention(this.items);

  static const empty = FinanceAttention([]);

  /// Derives every queue from the module's own loaded data.
  ///
  /// [ledger] is the **whole** ledger, not the window's slice — see the library
  /// note. [statements] is passed so a broken control identity can lead the
  /// list; pass the current window's, since that is the arithmetic on screen.
  factory FinanceAttention.from({
    required List<FinanceLedgerEntry> ledger,
    required List<RefundRequest> refundRequests,
    FinanceMoneyStatements? statements,
  }) {
    var reviewCount = 0;
    var reviewAmount = 0.0;
    var strandedCount = 0;
    var strandedAmount = 0.0;
    var unpaidCount = 0;
    var unpaidAmount = 0.0;
    var partPaidCount = 0;
    var partPaidAmount = 0.0;
    var unpaidPackageCount = 0;
    var unpaidPackageAmount = 0.0;

    for (final entry in ledger) {
      if (entry.awaitingReview) {
        reviewCount++;
        reviewAmount += entry.amount;
      }

      if (entry.isUnreleasedLiability) {
        strandedCount++;
        strandedAmount += entry.amount;
      }

      if (entry.outstanding > 0) {
        partPaidCount++;
        partPaidAmount += entry.outstanding;
      }

      if (!entry.isCollectable) continue;
      if (entry.type == FinanceEntryType.subscription) {
        unpaidPackageCount++;
        unpaidPackageAmount += entry.amount;
      } else {
        unpaidCount++;
        unpaidAmount += entry.amount;
      }
    }

    var pendingRefunds = 0;
    var pendingRefundAmount = 0.0;
    for (final request in refundRequests) {
      if (request.status != RefundStatus.pending) continue;
      pendingRefunds++;
      pendingRefundAmount += request.amount;
    }

    // A receipt awaiting review is also, by construction, an uncollected fare
    // on a live seat. Counting it in both queues would double the money on
    // screen, so the review queue — the one with an action attached — wins and
    // the chase queue reports only what nobody is looking at.
    final chaseCount = (unpaidCount - reviewCount).clamp(0, unpaidCount);
    final chaseAmount = (unpaidAmount - reviewAmount).clamp(0.0, unpaidAmount);

    final items = <FinanceAttentionItem>[
      if (statements != null && !statements.identityHolds)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.identityBroken,
          count: 1,
          amount: statements.identityGap.abs(),
        ),
      if (reviewCount > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.receiptsAwaitingReview,
          count: reviewCount,
          amount: reviewAmount,
        ),
      if (pendingRefunds > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.refundRequestsPending,
          count: pendingRefunds,
          amount: pendingRefundAmount,
        ),
      if (strandedCount > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.collectedOnCancelledSeat,
          count: strandedCount,
          amount: strandedAmount,
        ),
      if (chaseCount > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.unpaidLiveBookings,
          count: chaseCount,
          amount: chaseAmount,
        ),
      if (partPaidCount > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.subscriptionsPartPaid,
          count: partPaidCount,
          amount: partPaidAmount,
        ),
      if (unpaidPackageCount > 0)
        FinanceAttentionItem(
          kind: FinanceAttentionKind.subscriptionsAwaitingPayment,
          count: unpaidPackageCount,
          amount: unpaidPackageAmount,
        ),
    ];

    // A broken control identity is pinned first whatever its size: it does not
    // mean "there is 25 ج.م to chase", it means every other figure on the
    // screen — including the amounts in the rows below it — may be wrong.
    // Ranking it by money would bury the one row that invalidates the rest.
    //
    // Everything else sorts by severity, then by exposure, which is the order
    // an owner would work them in anyway.
    items.sort((a, b) {
      final aPinned = a.kind == FinanceAttentionKind.identityBroken;
      final bPinned = b.kind == FinanceAttentionKind.identityBroken;
      if (aPinned != bPinned) return aPinned ? -1 : 1;

      final bySeverity = a.severity.index.compareTo(b.severity.index);
      return bySeverity != 0 ? bySeverity : b.amount.compareTo(a.amount);
    });

    return FinanceAttention(items);
  }

  bool get isClear => items.isEmpty;

  /// Every pound represented by a queue, excluding the control-identity gap —
  /// that is a measurement error, not an amount of money anyone owes.
  double get totalAtRisk => items
      .where((i) => i.kind != FinanceAttentionKind.identityBroken)
      .fold(0.0, (sum, item) => sum + item.amount);

  /// Rows the owner has to act on, whatever their size.
  int get totalItems => items.fold(0, (sum, item) => sum + item.count);
}
