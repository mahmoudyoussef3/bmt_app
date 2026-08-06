import 'wallet_vocabulary.dart';

/// One immutable line of the ledger.
///
/// [amount] is signed — credits positive, debits negative — because that is what
/// makes `Σ amount = balance` hold with no rule anyone has to remember. The UI
/// reads [isCredit] rather than the kind, so a reversal (whose direction mirrors
/// whatever it reverses) renders correctly without a special case.
class WalletTransaction {
  final String id;

  /// Gapless per wallet. Shown in the UI because the customer's question is
  /// never "what was the amount", it is "why is my balance this" — and a ledger
  /// without a running position cannot answer it.
  final int seq;
  final WalletKind kind;
  final String category;
  final WalletSource source;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final WalletEntryStatus status;
  final String reason;
  final String? notes;

  final String? bookingId;
  final String? bookingNumber;
  final String? refundId;

  /// Set on a reversal: the entry this one cancels.
  final String? reversesTransactionId;

  /// Set on a reversed entry: the reversal that cancelled it. A struck-through
  /// row links to what corrected it rather than just looking cancelled.
  final String? reversedBy;

  final String? performedBy;
  final String performedByName;
  final String? performedByRole;
  final DateTime createdAt;

  /// Populated on the office-wide ledger, absent on a single customer's history
  /// (where the customer is the page).
  final String? clientId;
  final String? clientName;
  final String? clientPhone;

  const WalletTransaction({
    required this.id,
    required this.seq,
    required this.kind,
    required this.category,
    required this.source,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.reason,
    required this.performedByName,
    required this.createdAt,
    this.notes,
    this.bookingId,
    this.bookingNumber,
    this.refundId,
    this.reversesTransactionId,
    this.reversedBy,
    this.performedBy,
    this.performedByRole,
    this.clientId,
    this.clientName,
    this.clientPhone,
  });

  bool get isCredit => amount > 0;
  bool get isReversed => status == WalletEntryStatus.reversed;
  bool get isReversal => kind == WalletKind.reversal;
  String get categoryLabel => WalletCategories.labelOf(category);
}

/// A page of the office-wide financial activity search (surface 3).
class WalletLedgerPage {
  final int total;
  final double sumCredit;
  final double sumDebit;
  final List<WalletTransaction> rows;

  const WalletLedgerPage({
    required this.total,
    required this.sumCredit,
    required this.sumDebit,
    required this.rows,
  });

  const WalletLedgerPage.empty()
    : total = 0,
      sumCredit = 0,
      sumDebit = 0,
      rows = const [];

  double get net => sumCredit - sumDebit;
}

/// The filter set behind surface 3 (§8.3).
///
/// Serialised straight into the RPC's `p_filters` jsonb: one object in, one
/// definition of each predicate server-side, and no chance of the count and the
/// page disagreeing because they were filtered differently.
class WalletLedgerFilters {
  final String? clientId;
  final String? bookingId;
  final String? performedBy;
  final Set<WalletKind> kinds;
  final Set<String> categories;
  final Set<WalletEntryStatus> statuses;
  final Set<WalletSource> sources;
  final DateTime? from;
  final DateTime? to;
  final double? minAmount;
  final double? maxAmount;

  /// null = both, true = credits, false = debits.
  final bool? creditsOnly;

  /// Isolates corrected entries — a reversal or an entry that was reversed.
  final bool? hasReversal;
  final String? search;

  const WalletLedgerFilters({
    this.clientId,
    this.bookingId,
    this.performedBy,
    this.kinds = const {},
    this.categories = const {},
    this.statuses = const {},
    this.sources = const {},
    this.from,
    this.to,
    this.minAmount,
    this.maxAmount,
    this.creditsOnly,
    this.hasReversal,
    this.search,
  });

  bool get isEmpty =>
      clientId == null &&
      bookingId == null &&
      performedBy == null &&
      kinds.isEmpty &&
      categories.isEmpty &&
      statuses.isEmpty &&
      sources.isEmpty &&
      from == null &&
      to == null &&
      minAmount == null &&
      maxAmount == null &&
      creditsOnly == null &&
      hasReversal == null &&
      (search == null || search!.trim().isEmpty);

  Map<String, dynamic> toJson() => {
    if (clientId != null) 'client_id': clientId,
    if (bookingId != null) 'booking_id': bookingId,
    if (performedBy != null) 'performed_by': performedBy,
    if (kinds.isNotEmpty) 'kinds': kinds.map((k) => k.dbValue).toList(),
    if (categories.isNotEmpty) 'categories': categories.toList(),
    if (statuses.isNotEmpty) 'statuses': statuses.map((s) => s.dbValue).toList(),
    if (sources.isNotEmpty) 'sources': sources.map((s) => s.dbValue).toList(),
    if (from != null) 'date_from': from!.toUtc().toIso8601String(),
    if (to != null) 'date_to': to!.toUtc().toIso8601String(),
    if (minAmount != null) 'min_amount': minAmount,
    if (maxAmount != null) 'max_amount': maxAmount,
    if (creditsOnly != null) 'direction': creditsOnly! ? 'credit' : 'debit',
    if (hasReversal != null) 'has_reversal': hasReversal,
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
  };

  WalletLedgerFilters copyWith({
    String? clientId,
    String? bookingId,
    String? performedBy,
    Set<WalletKind>? kinds,
    Set<String>? categories,
    Set<WalletEntryStatus>? statuses,
    Set<WalletSource>? sources,
    DateTime? from,
    DateTime? to,
    double? minAmount,
    double? maxAmount,
    bool? creditsOnly,
    bool? hasReversal,
    String? search,
    bool clearClient = false,
    bool clearDates = false,
    bool clearAmounts = false,
    bool clearDirection = false,
    bool clearReversal = false,
    bool clearPerformer = false,
  }) {
    return WalletLedgerFilters(
      clientId: clearClient ? null : (clientId ?? this.clientId),
      bookingId: bookingId ?? this.bookingId,
      performedBy: clearPerformer ? null : (performedBy ?? this.performedBy),
      kinds: kinds ?? this.kinds,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      sources: sources ?? this.sources,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      creditsOnly: clearDirection ? null : (creditsOnly ?? this.creditsOnly),
      hasReversal: clearReversal ? null : (hasReversal ?? this.hasReversal),
      search: search ?? this.search,
    );
  }
}
