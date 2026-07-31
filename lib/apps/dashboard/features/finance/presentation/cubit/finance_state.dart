import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';

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
  final FinancePeriod period;
  final DateTime loadedAt;

  /// True when the backing query hit its row cap, so the window may be missing
  /// older movements. Surfaced to the operator rather than silently swallowed.
  final bool ledgerCapReached;

  final FinanceSection section;

  // Ledger tab controls.
  final String searchQuery;
  final FinanceEntryType? typeFilter;
  final FinancePaymentMethod? methodFilter;
  final PaymentStatus? statusFilter;
  final int ledgerPage;

  final bool exporting;
  final String? actionMessage;

  /// Derived once per state so every tab reads identical numbers.
  final FinanceAnalytics analytics;

  FinanceLoaded({
    required this.ledger,
    required this.refundRequests,
    required this.subscriptions,
    required this.loadedAt,
    this.period = FinancePeriod.month,
    this.ledgerCapReached = false,
    this.section = FinanceSection.overview,
    this.searchQuery = '',
    this.typeFilter,
    this.methodFilter,
    this.statusFilter,
    this.ledgerPage = 0,
    this.exporting = false,
    this.actionMessage,
  }) : analytics = FinanceAnalytics.from(
         ledger: ledger,
         period: period,
         now: loadedAt,
       );

  static const ledgerPageSize = 25;

  /// Packages that are currently earning — a live count, not a period figure.
  int get activeSubscriptions => subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .length;

  /// Refund requests still awaiting a decision elsewhere in the dashboard:
  /// money the office may still have to give back.
  List<RefundRequest> get pendingRefundRequests => refundRequests
      .where((r) => r.status == RefundStatus.pending)
      .toList();

  double get pendingRefundAmount =>
      pendingRefundRequests.fold(0.0, (sum, r) => sum + r.amount);

  /// The window's rows after the ledger tab's own search and filters.
  List<FinanceLedgerEntry> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    return analytics.entries.where((entry) {
      final matchesQuery =
          query.isEmpty ||
          entry.party.toLowerCase().contains(query) ||
          entry.reference.toLowerCase().contains(query) ||
          entry.id.toLowerCase().contains(query);
      final matchesType = typeFilter == null || entry.type == typeFilter;
      final matchesMethod = methodFilter == null || entry.method == methodFilter;
      final matchesStatus = statusFilter == null || entry.status == statusFilter;
      return matchesQuery && matchesType && matchesMethod && matchesStatus;
    }).toList();
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

  FinanceLoaded copyWith({
    List<FinanceLedgerEntry>? ledger,
    List<RefundRequest>? refundRequests,
    List<SubscriptionRecord>? subscriptions,
    FinancePeriod? period,
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
    int? ledgerPage,
    bool? exporting,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return FinanceLoaded(
      ledger: ledger ?? this.ledger,
      refundRequests: refundRequests ?? this.refundRequests,
      subscriptions: subscriptions ?? this.subscriptions,
      loadedAt: loadedAt ?? this.loadedAt,
      period: period ?? this.period,
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
      ledgerPage: ledgerPage ?? this.ledgerPage,
      exporting: exporting ?? this.exporting,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}
