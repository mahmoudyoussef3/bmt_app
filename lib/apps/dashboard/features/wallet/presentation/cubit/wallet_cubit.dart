import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../../domain/usecases/wallet_usecases.dart';
import 'wallet_state.dart';

/// Drives محفظة العملاء.
///
/// Two conventions run through every method here:
///
///  1. **A failed action never blanks a loaded screen.** Only the first load can
///     produce [WalletErrorState]. Everything after that reports through
///     `actionError`, because the operator's search, selection and open history
///     are worth more than a tidy error page.
///
///  2. **Every write re-reads.** The balance on screen after a posting comes
///     from the server, never from local arithmetic — two operators can act at
///     once, and the ledger is append-only, so the truthful balance is whatever
///     the sum of both entries is rather than whatever this client predicted.
class WalletCubit extends Cubit<WalletState> {
  final GetWalletWorkspaceUseCase _getWorkspace;
  final SearchWalletDirectoryUseCase _searchDirectory;
  final GetWalletSummaryUseCase _getSummary;
  final GetWalletLedgerUseCase _getLedger;
  final GetRefundQueueUseCase _getRefundQueue;
  final GetRefundableBookingsUseCase _getRefundableBookings;
  final GetCancelledTripsUseCase _getCancelledTrips;
  final AdjustWalletUseCase _adjust;
  final ReverseWalletTransactionUseCase _reverse;
  final SetWalletStatusUseCase _setStatus;
  final VerifyWalletChainUseCase _verifyChain;
  final CreateRefundUseCase _createRefund;
  final DecideRefundUseCase _decideRefund;
  final RefundTripBatchUseCase _refundTripBatch;

  WalletCubit({
    required GetWalletWorkspaceUseCase getWorkspace,
    required SearchWalletDirectoryUseCase searchDirectory,
    required GetWalletSummaryUseCase getSummary,
    required GetWalletLedgerUseCase getLedger,
    required GetRefundQueueUseCase getRefundQueue,
    required GetRefundableBookingsUseCase getRefundableBookings,
    required GetCancelledTripsUseCase getCancelledTrips,
    required AdjustWalletUseCase adjust,
    required ReverseWalletTransactionUseCase reverse,
    required SetWalletStatusUseCase setStatus,
    required VerifyWalletChainUseCase verifyChain,
    required CreateRefundUseCase createRefund,
    required DecideRefundUseCase decideRefund,
    required RefundTripBatchUseCase refundTripBatch,
  }) : _getWorkspace = getWorkspace,
       _searchDirectory = searchDirectory,
       _getSummary = getSummary,
       _getLedger = getLedger,
       _getRefundQueue = getRefundQueue,
       _getRefundableBookings = getRefundableBookings,
       _getCancelledTrips = getCancelledTrips,
       _adjust = adjust,
       _reverse = reverse,
       _setStatus = setStatus,
       _verifyChain = verifyChain,
       _createRefund = createRefund,
       _decideRefund = decideRefund,
       _refundTripBatch = refundTripBatch,
       super(const WalletLoadingState());

  WalletLoadedState? get _loaded =>
      state is WalletLoadedState ? state as WalletLoadedState : null;

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(const WalletLoadingState());
    try {
      final workspace = await _getWorkspace();
      emit(
        WalletLoadedState(
          overview: workspace.overview,
          directory: workspace.directory,
        ),
      );
      // The pending-refund count is a control the header shows, so the queue is
      // fetched on first load rather than lazily when its tab is opened.
      await loadRefundQueue();
    } catch (e) {
      emit(WalletErrorState(_clean(e)));
    }
  }

  /// Silent re-read of everything currently on screen. Used after every write
  /// and by the header's refresh button; it never shows a spinner over a good
  /// screen and never tears one down on failure.
  Future<void> refresh() async {
    final current = _loaded;
    if (current == null) return;
    try {
      final workspace = await _getWorkspace(search: current.directorySearch);
      if (isClosed) return;
      emit(
        current.copyWith(
          overview: workspace.overview,
          directory: workspace.directory,
        ),
      );
      if (current.selectedClientId != null) {
        await _loadSummary(current.selectedClientId!);
      }
      if (current.tab == WalletTab.activity) await loadLedger();
      await loadRefundQueue();
    } catch (_) {
      // Keep the last good picture. The operator can retry from the header.
    }
  }

  Future<void> searchDirectory(String query) async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(directorySearch: query));
    try {
      final page = await _searchDirectory(search: query);
      if (isClosed) return;
      final now = _loaded;
      // Guard against an out-of-order response: only apply the page if the
      // query it was fetched for is still the one in the box.
      if (now != null && now.directorySearch == query) {
        emit(now.copyWith(directory: page));
      }
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> selectCustomer(String? clientId) async {
    final current = _loaded;
    if (current == null) return;
    if (clientId == null) {
      emit(current.copyWith(clearSelection: true, clearChainVerification: true));
      return;
    }
    emit(
      current.copyWith(
        selectedClientId: clientId,
        summary: null,
        detailLoading: true,
        clearChainVerification: true,
      ),
    );
    await _loadSummary(clientId);
  }

  Future<void> _loadSummary(String clientId) async {
    try {
      final summary = await _getSummary(clientId);
      if (isClosed) return;
      final current = _loaded;
      // The operator may have moved on while this was in flight.
      if (current == null || current.selectedClientId != clientId) return;
      emit(current.copyWith(summary: summary, detailLoading: false));
    } catch (e) {
      final current = _loaded;
      if (current == null || isClosed) return;
      emit(current.copyWith(detailLoading: false, actionError: _clean(e)));
    }
  }

  void setTab(WalletTab tab) {
    final current = _loaded;
    if (current == null || current.tab == tab) return;
    emit(current.copyWith(tab: tab));
    if (tab == WalletTab.activity && current.ledger.rows.isEmpty) loadLedger();
    if (tab == WalletTab.refunds) loadRefundQueue();
  }

  Future<void> applyFilters(WalletLedgerFilters filters) async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(filters: filters, ledgerLoading: true));
    await loadLedger();
  }

  Future<void> loadLedger() async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(ledgerLoading: true));
    try {
      final page = await _getLedger(filters: current.filters);
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(now.copyWith(ledger: page, ledgerLoading: false));
    } catch (e) {
      final now = _loaded;
      if (now == null || isClosed) return;
      emit(now.copyWith(ledgerLoading: false, actionError: _clean(e)));
    }
  }

  Future<void> loadRefundQueue() async {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(queueLoading: true));
    try {
      final queue = await _getRefundQueue();
      if (isClosed) return;
      final now = _loaded;
      if (now == null) return;
      emit(now.copyWith(refundQueue: queue, queueLoading: false));
    } catch (e) {
      final now = _loaded;
      if (now == null || isClosed) return;
      emit(now.copyWith(queueLoading: false, actionError: _clean(e)));
    }
  }

  /// Fetched on demand by the refund dialog rather than held in state: it is a
  /// per-customer list that is only ever read while that dialog is open.
  Future<List<RefundableBooking>> refundableBookings(String clientId) =>
      _getRefundableBookings(clientId);

  Future<List<CancelledTripRefundTarget>> cancelledTrips() =>
      _getCancelledTrips();

  // ── Actions ──────────────────────────────────────────────────────────────
  //
  // Each returns `null` on success or the operator-facing message on failure, so
  // a dialog can stay open and show the reason instead of closing on a refusal.

  Future<String?> adjust({
    required WalletKind kind,
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) {
    return _run(() async {
      final entry = await _adjust(
        kind: kind,
        clientId: clientId,
        amount: amount,
        category: category,
        reason: reason,
        notes: notes,
        requestKey: requestKey,
        wallet: _loaded?.selectedWallet,
      );
      return _successMessage(kind, entry);
    });
  }

  Future<String?> reverseEntry({
    required WalletTransaction transaction,
    required String reason,
    required String category,
    required String requestKey,
  }) {
    return _run(() async {
      await _reverse(
        transaction: transaction,
        reason: reason,
        category: category,
        requestKey: requestKey,
        wallet: _loaded?.selectedWallet,
      );
      return 'تم تسجيل العملية العكسية.';
    });
  }

  Future<String?> setWalletStatus({
    required String clientId,
    required WalletStatus status,
    required String reason,
  }) {
    return _run(() async {
      await _setStatus(clientId: clientId, status: status, reason: reason);
      return status == WalletStatus.frozen
          ? 'تم تجميد المحفظة.'
          : 'تم إلغاء تجميد المحفظة.';
    });
  }

  Future<String?> createRefund({
    required RefundableBooking booking,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
    bool hasClient = true,
  }) {
    return _run(() async {
      final refund = await _createRefund(
        booking: booking,
        amount: amount,
        category: category,
        reason: reason,
        notes: notes,
        settlement: settlement,
        requestKey: requestKey,
        hasClient: hasClient,
      );
      return refund.status == RefundStatus.settled
          ? 'تم تنفيذ الاسترداد.'
          : 'تم إرسال طلب الاسترداد للمراجعة.';
    });
  }

  Future<String?> decideRefund({
    required RefundRequest refund,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement = RefundSettlement.wallet,
    String? reason,
    required String requestKey,
  }) {
    return _run(() async {
      await _decideRefund(
        refund: refund,
        approve: approve,
        approvedAmount: approvedAmount,
        settlement: settlement,
        reason: reason,
        requestKey: requestKey,
      );
      return approve ? 'تم اعتماد الاسترداد وتنفيذه.' : 'تم رفض طلب الاسترداد.';
    });
  }

  Future<String?> refundTripBatch({
    required CancelledTripRefundTarget trip,
    required String reason,
    String category = 'trip_cancelled',
    RefundSettlement settlement = RefundSettlement.wallet,
    required String requestKey,
  }) {
    return _run(() async {
      final result = await _refundTripBatch(
        trip: trip,
        category: category,
        reason: reason,
        settlement: settlement,
        requestKey: requestKey,
      );
      return 'تم رد ${result.refunded} حجز'
          '${result.skipped > 0 ? ' وتخطّي ${result.skipped}' : ''}.';
    });
  }

  /// Recomputes the sequence and hash chain of the open wallet.
  ///
  /// A divergence auto-freezes the wallet server-side and raises an urgent
  /// alert, so this reports rather than decides — but it reports loudly, because
  /// a wallet whose history cannot be trusted must not keep transacting.
  Future<String?> verifyChain() async {
    final current = _loaded;
    final clientId = current?.selectedClientId;
    if (current == null || clientId == null) return null;

    emit(current.copyWith(busy: true));
    try {
      final result = await _verifyChain(clientId);
      if (isClosed) return null;
      final now = _loaded;
      if (now == null) return null;
      emit(
        now.copyWith(
          busy: false,
          chainVerification: result,
          actionMessage: result.verified
              ? 'سجل المحفظة سليم — ${result.entries} حركة متطابقة.'
              : null,
          actionError: result.verified ? null : result.faultLabel,
        ),
      );
      // A fault freezes the wallet server-side; re-read so the screen shows it.
      if (!result.verified) await refresh();
      return result.verified ? null : result.faultLabel;
    } catch (e) {
      return _fail(e);
    }
  }

  /// The shared action path: mark busy, run, re-read, report.
  ///
  /// Re-reading on *success only* is deliberate — a refused action changed
  /// nothing, so a refresh would just cost the operator a round trip before they
  /// can read why it was refused.
  Future<String?> _run(Future<String> Function() action) async {
    final current = _loaded;
    if (current == null) return null;
    emit(current.copyWith(busy: true));
    try {
      final message = await action();
      if (isClosed) return null;
      await refresh();
      if (isClosed) return null;
      final now = _loaded;
      if (now != null) {
        emit(now.copyWith(busy: false, actionMessage: message));
      }
      return null;
    } catch (e) {
      return _fail(e);
    }
  }

  String _fail(Object error) {
    final message = _clean(error);
    final current = _loaded;
    if (current != null && !isClosed) {
      emit(current.copyWith(busy: false, actionError: message));
    }
    return message;
  }

  String _successMessage(WalletKind kind, WalletTransaction entry) {
    final label = switch (kind) {
      WalletKind.cashback => 'تم منح كاش باك',
      WalletKind.manualCredit => 'تمت إضافة الرصيد',
      WalletKind.manualDebit => 'تم خصم الرصيد',
      _ => 'تم تسجيل العملية',
    };
    return '$label — الرصيد الآن ${entry.balanceAfter.toStringAsFixed(2)} ج.م.';
  }

  String _clean(Object error) =>
      error.toString().replaceAll('Exception: ', '').trim();
}
