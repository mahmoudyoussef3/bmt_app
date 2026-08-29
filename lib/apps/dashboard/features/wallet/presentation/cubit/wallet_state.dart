import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../models/wallet_views.dart';

/// The module's four surfaces (§8.1), as one screen with three tabs plus the
/// detail pane the directory opens.
enum WalletTab {
  directory('العملاء والمحافظ'),
  activity('الحركات المالية'),
  refunds('طلبات الاسترداد');

  const WalletTab(this.label);

  final String label;
}

sealed class WalletState {
  const WalletState();
}

class WalletLoadingState extends WalletState {
  const WalletLoadingState();
}

class WalletErrorState extends WalletState {
  final String message;

  const WalletErrorState(this.message);
}

/// The loaded module.
///
/// A failed *load* becomes [WalletErrorState]; a failed *action* keeps this
/// state and surfaces [actionError]. Dropping to an error screen after a refused
/// debit would discard the operator's search, their selected customer and the
/// history they were reading — and the refusal is usually the point.
class WalletLoadedState extends WalletState {
  final WalletOverview overview;
  final WalletDirectoryPage directory;
  final String directorySearch;

  /// The directory's own narrowing and ordering, applied to [directory]'s rows.
  final WalletDirectoryFilters directoryFilters;
  final int directoryPage;

  /// The customer whose wallet is open in the detail pane, and their resolved
  /// summary. [summary] lags [selectedClientId] by one round trip, which is what
  /// [detailLoading] renders.
  final String? selectedClientId;
  final WalletSummary? summary;
  final bool detailLoading;

  final WalletTab tab;

  final WalletLedgerPage ledger;
  final WalletLedgerFilters filters;
  final bool ledgerLoading;

  /// Reorders the page [filters] returned. Client-side by definition — see
  /// [WalletActivitySort].
  final WalletActivitySort activitySort;
  final int activityPage;

  final List<RefundRequest> refundQueue;
  final bool queueLoading;

  /// The refund queue's narrowing and ordering, applied to [refundQueue].
  final WalletRefundFilters refundFilters;
  final int refundPage;

  /// True while a write is in flight, so buttons can disable themselves rather
  /// than let an impatient second tap become a second transaction. The request
  /// key makes a duplicate harmless; this makes it unlikely.
  final bool busy;

  /// One-shot feedback. Neither survives a rebuild triggered by anything else,
  /// because a sticky message re-fires its snackbar on every refresh.
  final String? actionError;
  final String? actionMessage;

  /// The most recent chain verification, kept so its verdict stays on screen
  /// rather than vanishing with the snackbar that announced it.
  final WalletChainVerification? chainVerification;

  const WalletLoadedState({
    required this.overview,
    required this.directory,
    this.directorySearch = '',
    this.directoryFilters = const WalletDirectoryFilters(),
    this.directoryPage = 0,
    this.selectedClientId,
    this.summary,
    this.detailLoading = false,
    this.tab = WalletTab.directory,
    this.ledger = const WalletLedgerPage.empty(),
    this.filters = const WalletLedgerFilters(),
    this.ledgerLoading = false,
    this.activitySort = WalletActivitySort.newest,
    this.activityPage = 0,
    this.refundQueue = const [],
    this.queueLoading = false,
    this.refundFilters = const WalletRefundFilters(),
    this.refundPage = 0,
    this.busy = false,
    this.actionError,
    this.actionMessage,
    this.chainVerification,
  });

  /// The wallet currently on screen, or an empty one. Never null, so callers do
  /// not have to decide what "no wallet row yet" means — it means zero.
  Wallet get selectedWallet => summary?.wallet ?? const Wallet.empty();

  bool get hasSelection => selectedClientId != null;

  int get openRefundCount =>
      refundQueue.where((refund) => refund.isOpen).length;

  // ## The three lists, derived rather than stored
  //
  // Each tab's rows are its source list read through its own filter object, and
  // the page in view is a window onto that. Nothing here is cached in a field:
  // a stored copy is a second answer to "what is on screen", and the whole
  // point of the toolbar, the KPI tiles and the list agreeing is that there is
  // only one.

  /// The directory rows matching the current scope, in the chosen order.
  List<WalletDirectoryEntry> get directoryRows =>
      directoryFilters.apply(directory.rows);

  List<WalletDirectoryEntry> get directoryPageRows =>
      walletPageOf(directoryRows, directoryPage);

  /// True when the RPC returned its ceiling rather than every customer, so the
  /// list can say the scope it is narrowing is a page and not the whole base.
  bool get directoryCapReached => directory.total > directory.rows.length;

  List<WalletTransaction> get activityRows => activitySort.apply(ledger.rows);

  List<WalletTransaction> get activityPageRows =>
      walletPageOf(activityRows, activityPage);

  bool get activityCapReached => ledger.total > ledger.rows.length;

  List<RefundRequest> get refundRows => refundFilters.apply(refundQueue);

  List<RefundRequest> get refundPageRows =>
      walletPageOf(refundRows, refundPage);

  /// How many refunds fall in [scope], counted from the same list the scope
  /// filters — which is what lets a KPI tile open exactly the rows it counted.
  int refundCountOf(WalletRefundScope scope) =>
      refundQueue.where(scope.matches).length;

  WalletLoadedState copyWith({
    WalletOverview? overview,
    WalletDirectoryPage? directory,
    String? directorySearch,
    WalletDirectoryFilters? directoryFilters,
    int? directoryPage,
    String? selectedClientId,
    WalletSummary? summary,
    bool? detailLoading,
    WalletTab? tab,
    WalletLedgerPage? ledger,
    WalletLedgerFilters? filters,
    bool? ledgerLoading,
    WalletActivitySort? activitySort,
    int? activityPage,
    List<RefundRequest>? refundQueue,
    bool? queueLoading,
    WalletRefundFilters? refundFilters,
    int? refundPage,
    bool? busy,
    String? actionError,
    String? actionMessage,
    WalletChainVerification? chainVerification,
    bool clearSelection = false,
    bool clearChainVerification = false,
  }) {
    return WalletLoadedState(
      overview: overview ?? this.overview,
      directory: directory ?? this.directory,
      directorySearch: directorySearch ?? this.directorySearch,
      directoryFilters: directoryFilters ?? this.directoryFilters,
      directoryPage: directoryPage ?? this.directoryPage,
      selectedClientId: clearSelection
          ? null
          : (selectedClientId ?? this.selectedClientId),
      summary: clearSelection ? null : (summary ?? this.summary),
      detailLoading: detailLoading ?? this.detailLoading,
      tab: tab ?? this.tab,
      ledger: ledger ?? this.ledger,
      filters: filters ?? this.filters,
      ledgerLoading: ledgerLoading ?? this.ledgerLoading,
      activitySort: activitySort ?? this.activitySort,
      activityPage: activityPage ?? this.activityPage,
      refundQueue: refundQueue ?? this.refundQueue,
      queueLoading: queueLoading ?? this.queueLoading,
      refundFilters: refundFilters ?? this.refundFilters,
      refundPage: refundPage ?? this.refundPage,
      busy: busy ?? this.busy,

      actionError: actionError,
      actionMessage: actionMessage,
      chainVerification: clearChainVerification
          ? null
          : (chainVerification ?? this.chainVerification),
    );
  }
}
