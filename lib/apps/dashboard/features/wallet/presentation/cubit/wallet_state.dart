import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';

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

  final List<RefundRequest> refundQueue;
  final bool queueLoading;

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
    this.selectedClientId,
    this.summary,
    this.detailLoading = false,
    this.tab = WalletTab.directory,
    this.ledger = const WalletLedgerPage.empty(),
    this.filters = const WalletLedgerFilters(),
    this.ledgerLoading = false,
    this.refundQueue = const [],
    this.queueLoading = false,
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

  WalletLoadedState copyWith({
    WalletOverview? overview,
    WalletDirectoryPage? directory,
    String? directorySearch,
    String? selectedClientId,
    WalletSummary? summary,
    bool? detailLoading,
    WalletTab? tab,
    WalletLedgerPage? ledger,
    WalletLedgerFilters? filters,
    bool? ledgerLoading,
    List<RefundRequest>? refundQueue,
    bool? queueLoading,
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
      selectedClientId: clearSelection
          ? null
          : (selectedClientId ?? this.selectedClientId),
      summary: clearSelection ? null : (summary ?? this.summary),
      detailLoading: detailLoading ?? this.detailLoading,
      tab: tab ?? this.tab,
      ledger: ledger ?? this.ledger,
      filters: filters ?? this.filters,
      ledgerLoading: ledgerLoading ?? this.ledgerLoading,
      refundQueue: refundQueue ?? this.refundQueue,
      queueLoading: queueLoading ?? this.queueLoading,
      busy: busy ?? this.busy,
      // Deliberately NOT carried forward: both are one-shot.
      actionError: actionError,
      actionMessage: actionMessage,
      chainVerification: clearChainVerification
          ? null
          : (chainVerification ?? this.chainVerification),
    );
  }
}
