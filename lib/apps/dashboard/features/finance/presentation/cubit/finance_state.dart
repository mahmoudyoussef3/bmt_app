import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_attention.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money_model.dart';

/// The four money views. Nothing here decides anything — the section indexes
/// map to reports, not to workflows.
enum FinanceSection {
  overview('نظرة عامة'),
  ledger('الحركات المالية'),
  analytics('التحليلات'),
  reports('التقارير');

  final String label;
  const FinanceSection(this.label);
}

/// How the ledger table is ordered. Money and time are the only two orders an
/// operator ever asks for; sorting by client name is a search, and the search
/// box already exists.
enum FinanceLedgerSort {
  newest('الأحدث أولاً'),
  oldest('الأقدم أولاً'),
  amountDesc('الأكبر مبلغاً'),
  amountAsc('الأصغر مبلغاً');

  final String label;
  const FinanceLedgerSort(this.label);
}

sealed class FinanceState {
  const FinanceState();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceError extends FinanceState {
  final String message;
  const FinanceError(this.message);
}

class FinanceLoaded extends FinanceState {
  /// The full ledger, unfiltered. [analytics] is the window-scoped view of it.
  final List<FinanceLedgerEntry> ledger;

  /// Refund *requests* — an outstanding-liability signal, kept out of the
  /// ledger so an approved refund is never subtracted twice (it is already
  /// mirrored on its booking).
  final List<RefundRequest> refundRequests;

  final List<SubscriptionRecord> subscriptions;

  /// The wallet-side facts behind the three statements (§7). Held whole, like
  /// the ledger, so switching period re-derives the liability position without a
  /// round trip — and so the KPI band, the identity check and the statement can
  /// never be computed from three different snapshots.
  final WalletFinancePosition walletPosition;

  final FinancePeriod period;

  /// The two dates behind [FinancePeriod.custom]. Ignored for every other
  /// preset, and kept across preset changes so switching away and back does not
  /// lose the operator's range.
  final FinanceDateRange? customRange;

  final DateTime loadedAt;

  /// True when the backing query hit its row cap, so the window may be missing
  /// older movements. Surfaced to the operator rather than silently swallowed.
  final bool ledgerCapReached;

  final FinanceSection section;

  final String searchQuery;
  final FinanceEntryType? typeFilter;
  final FinancePaymentMethod? methodFilter;
  final PaymentStatus? statusFilter;
  final FinanceLedgerSort ledgerSort;
  final int ledgerPage;

  final bool exporting;
  final String? actionMessage;

  /// Derived once per state so every tab reads identical numbers.
  ///
  /// Deriving is cheap per *load* and not per *keystroke*: it walks the whole
  /// ledger twice (this window and the comparison window) and buckets it six
  /// ways. Recomputing that when the operator types in the search box or pages
  /// the table is the module's most expensive avoidable cost, so [copyWith]
  /// carries it forward whenever none of its inputs moved.
  final FinanceAnalytics analytics;

  /// What needs a decision, across the **whole** book rather than the selected
  /// window — see `finance_attention.dart`. Carried forward by [copyWith] on
  /// the same terms as [analytics].
  final FinanceAttention attention;

  /// Loads a fresh state and derives everything from it exactly once.
  ///
  /// A factory rather than a generative constructor because [analytics] and
  /// [attention] share work: the attention list needs the current window's
  /// control identity, and computing the analytics twice to get it would double
  /// the module's only expensive operation.
  factory FinanceLoaded({
    required List<FinanceLedgerEntry> ledger,
    required List<RefundRequest> refundRequests,
    required List<SubscriptionRecord> subscriptions,
    required DateTime loadedAt,
    WalletFinancePosition walletPosition = const WalletFinancePosition.empty(),
    FinancePeriod period = FinancePeriod.month,
    FinanceDateRange? customRange,
    bool ledgerCapReached = false,
    FinanceSection section = FinanceSection.overview,
    String searchQuery = '',
    FinanceEntryType? typeFilter,
    FinancePaymentMethod? methodFilter,
    PaymentStatus? statusFilter,
    FinanceLedgerSort ledgerSort = FinanceLedgerSort.newest,
    int ledgerPage = 0,
    bool exporting = false,
    String? actionMessage,
  }) {
    final analytics = FinanceAnalytics.from(
      ledger: ledger,
      period: period,
      now: loadedAt,
      wallet: walletPosition,
      customRange: customRange,
    );

    return FinanceLoaded._derived(
      ledger: ledger,
      refundRequests: refundRequests,
      subscriptions: subscriptions,
      walletPosition: walletPosition,
      loadedAt: loadedAt,
      period: period,
      customRange: customRange,
      ledgerCapReached: ledgerCapReached,
      section: section,
      searchQuery: searchQuery,
      typeFilter: typeFilter,
      methodFilter: methodFilter,
      statusFilter: statusFilter,
      ledgerSort: ledgerSort,
      ledgerPage: ledgerPage,
      exporting: exporting,
      actionMessage: actionMessage,
      analytics: analytics,
      attention: FinanceAttention.from(
        ledger: ledger,
        refundRequests: refundRequests,
        statements: analytics.statements,
      ),
    );
  }

  /// Reuses derivations the caller has proven are still valid.
  FinanceLoaded._derived({
    required this.ledger,
    required this.refundRequests,
    required this.subscriptions,
    required this.walletPosition,
    required this.loadedAt,
    required this.period,
    required this.customRange,
    required this.ledgerCapReached,
    required this.section,
    required this.searchQuery,
    required this.typeFilter,
    required this.methodFilter,
    required this.statusFilter,
    required this.ledgerSort,
    required this.ledgerPage,
    required this.exporting,
    required this.actionMessage,
    required this.analytics,
    required this.attention,
  });

  static const ledgerPageSize = 25;

  /// Packages that are currently earning — a live count, not a period figure.
  int get activeSubscriptions =>
      subscriptions.where((s) => s.status == SubscriptionStatus.active).length;

  /// Refund requests still awaiting a decision elsewhere in the dashboard:
  /// money the office may still have to give back.
  List<RefundRequest> get pendingRefundRequests =>
      refundRequests.where((r) => r.status == RefundStatus.pending).toList();

  double get pendingRefundAmount =>
      pendingRefundRequests.fold(0.0, (sum, r) => sum + r.amount);

  /// The window's rows after the ledger tab's own search, filters and order.
  ///
  /// `late final` rather than a getter: the ledger tab reads it three times per
  /// build (the table, the totals strip, the page count) and the list can hold
  /// three thousand rows.
  late final List<FinanceLedgerEntry> filteredEntries = _filter();

  List<FinanceLedgerEntry> _filter() {
    final query = searchQuery.trim().toLowerCase();
    final rows = analytics.entries.where((entry) {
      final matchesQuery =
          query.isEmpty ||
          entry.party.toLowerCase().contains(query) ||
          entry.reference.toLowerCase().contains(query) ||
          entry.id.toLowerCase().contains(query) ||
          (entry.context.reference?.toLowerCase().contains(query) ?? false) ||
          (entry.context.phone?.contains(query) ?? false);
      final matchesType = typeFilter == null || entry.type == typeFilter;
      final matchesMethod =
          methodFilter == null || entry.method == methodFilter;
      final matchesStatus =
          statusFilter == null || entry.status == statusFilter;
      return matchesQuery && matchesType && matchesMethod && matchesStatus;
    }).toList();

    // `analytics.entries` is already newest-first, so the default order costs
    // nothing and only a deliberate choice pays for a sort.
    switch (ledgerSort) {
      case FinanceLedgerSort.newest:
        break;
      case FinanceLedgerSort.oldest:
        rows.sort((a, b) => a.date.compareTo(b.date));
      case FinanceLedgerSort.amountDesc:
        rows.sort((a, b) => b.amount.compareTo(a.amount));
      case FinanceLedgerSort.amountAsc:
        rows.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return rows;
  }

  /// Net money represented by whatever the ledger tab is currently showing, so
  /// a filtered view still totals honestly.
  double get filteredNet => filteredEntries
      .where((e) => e.isRealised)
      .fold(0.0, (sum, e) => sum + e.amount);

  bool get hasAnyFilter =>
      searchQuery.isNotEmpty ||
      typeFilter != null ||
      methodFilter != null ||
      statusFilter != null;

  /// True when the office has no financial history at all, as opposed to none
  /// *in this window*. The two need different empty states: one says "choose a
  /// wider period", the other says "sell something".
  bool get hasNoHistory => ledger.isEmpty;

  FinanceLoaded copyWith({
    List<FinanceLedgerEntry>? ledger,
    List<RefundRequest>? refundRequests,
    List<SubscriptionRecord>? subscriptions,
    WalletFinancePosition? walletPosition,
    FinancePeriod? period,
    FinanceDateRange? customRange,
    DateTime? loadedAt,
    bool? ledgerCapReached,
    FinanceSection? section,
    String? searchQuery,
    FinanceEntryType? typeFilter,
    bool clearTypeFilter = false,
    FinancePaymentMethod? methodFilter,
    bool clearMethodFilter = false,
    PaymentStatus? statusFilter,
    bool clearStatusFilter = false,
    FinanceLedgerSort? ledgerSort,
    int? ledgerPage,
    bool? exporting,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    final nextPeriod = period ?? this.period;
    final nextRange = customRange ?? this.customRange;
    final nextLedger = ledger ?? this.ledger;
    final nextRefunds = refundRequests ?? this.refundRequests;
    final nextWallet = walletPosition ?? this.walletPosition;
    final nextLoadedAt = loadedAt ?? this.loadedAt;

    // The five inputs the derivation reads. Filters, paging, the section and
    // the export flag are none of them, which is the whole point.
    final derivationHolds =
        identical(nextLedger, this.ledger) &&
        identical(nextRefunds, this.refundRequests) &&
        identical(nextWallet, this.walletPosition) &&
        nextPeriod == this.period &&
        identical(nextRange, this.customRange) &&
        nextLoadedAt == this.loadedAt;

    if (!derivationHolds) {
      return FinanceLoaded(
        ledger: nextLedger,
        refundRequests: nextRefunds,
        subscriptions: subscriptions ?? this.subscriptions,
        walletPosition: nextWallet,
        loadedAt: nextLoadedAt,
        period: nextPeriod,
        customRange: nextRange,
        ledgerCapReached: ledgerCapReached ?? this.ledgerCapReached,
        section: section ?? this.section,
        searchQuery: searchQuery ?? this.searchQuery,
        typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
        methodFilter: clearMethodFilter
            ? null
            : (methodFilter ?? this.methodFilter),
        statusFilter: clearStatusFilter
            ? null
            : (statusFilter ?? this.statusFilter),
        ledgerSort: ledgerSort ?? this.ledgerSort,
        ledgerPage: ledgerPage ?? this.ledgerPage,
        exporting: exporting ?? this.exporting,
        actionMessage: clearActionMessage
            ? null
            : (actionMessage ?? this.actionMessage),
      );
    }

    return FinanceLoaded._derived(
      ledger: nextLedger,
      refundRequests: nextRefunds,
      subscriptions: subscriptions ?? this.subscriptions,
      walletPosition: nextWallet,
      loadedAt: nextLoadedAt,
      period: nextPeriod,
      customRange: nextRange,
      ledgerCapReached: ledgerCapReached ?? this.ledgerCapReached,
      section: section ?? this.section,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      methodFilter: clearMethodFilter
          ? null
          : (methodFilter ?? this.methodFilter),
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      ledgerSort: ledgerSort ?? this.ledgerSort,
      ledgerPage: ledgerPage ?? this.ledgerPage,
      exporting: exporting ?? this.exporting,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      analytics: analytics,
      attention: attention,
    );
  }
}
