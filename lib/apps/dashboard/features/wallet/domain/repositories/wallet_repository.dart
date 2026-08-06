import '../entities/refund_request.dart';
import '../entities/wallet.dart';
import '../entities/wallet_summary.dart';
import '../entities/wallet_transaction.dart';
import '../entities/wallet_vocabulary.dart';

/// Read/act contract for the wallet module.
///
/// Office scoping is a server property, not a parameter: every RPC behind this
/// resolves the office from `current_office_id()` and refuses to accept one from
/// the caller, so there is no office id to pass and no way to pass the wrong one.
///
/// Keys on **walletId/clientId at the boundary only** (§3A.8) — nothing above
/// this line knows how a wallet is stored.
abstract class WalletRepository {
  // ── Reads ────────────────────────────────────────────────────────────────

  Future<WalletOverview> getOverview();

  Future<WalletDirectoryPage> getDirectory({
    String? search,
    int limit,
    int offset,
  });

  Future<WalletSummary> getSummary(String clientId);

  Future<WalletLedgerPage> getLedger({
    required WalletLedgerFilters filters,
    int limit,
    int offset,
  });

  /// The refund queue (surface 4). Read straight from `refund_requests` under
  /// the office RLS policy — the decision goes through an RPC, the list does not.
  Future<List<RefundRequest>> getRefundQueue({List<RefundStatus> statuses});

  Future<List<RefundableBooking>> getRefundableBookings(String clientId);

  Future<List<CancelledTripRefundTarget>> getCancelledTripsWithRefunds();

  // ── Writes ───────────────────────────────────────────────────────────────
  //
  // Each returns the resulting record so the caller can show what actually
  // happened rather than assume it. [requestKey] is generated once per dialog
  // open, so a double-tap or a retried request returns the original transaction
  // instead of posting a second one.

  Future<WalletTransaction> grantCashback({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  });

  Future<WalletTransaction> credit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  });

  Future<WalletTransaction> debit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  });

  /// Posts the inverse entry and marks the original reversed. Nothing
  /// disappears; both rows stay visible and linked.
  Future<WalletTransaction> reverse({
    required String transactionId,
    required String reason,
    required String category,
    required String requestKey,
  });

  Future<Wallet> setWalletStatus({
    required String clientId,
    required WalletStatus status,
    required String reason,
  });

  Future<WalletChainVerification> verifyChain(String clientId);

  /// Files a refund. When the caller holds the decide capability the server
  /// approves and settles it in the same transaction; otherwise it is born
  /// pending and lands in the queue.
  Future<RefundRequest> createRefund({
    required String bookingId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
  });

  Future<RefundRequest> decideRefund({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement,
    String? reason,
    required String requestKey,
  });

  /// One refund per confirmed booking on a cancelled trip, in one transaction
  /// under one batch key.
  Future<TripBatchRefundResult> refundTripBatch({
    required String tripId,
    required String category,
    required String reason,
    required RefundSettlement settlement,
    required String requestKey,
  });
}
