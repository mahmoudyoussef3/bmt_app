import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';

/// Transport contract for the wallet module. One implementation
/// ([SupabaseWalletDatasource]) today; the interface exists so the repository —
/// and every test above it — depends on the shape rather than on Supabase.
abstract class WalletDatasource {
  Future<WalletOverview> fetchOverview();

  Future<WalletDirectoryPage> fetchDirectory({
    String? search,
    required int limit,
    required int offset,
  });

  Future<WalletSummary> fetchSummary(String clientId);

  Future<WalletLedgerPage> fetchLedger({
    required Map<String, dynamic> filters,
    required int limit,
    required int offset,
  });

  Future<List<RefundRequest>> fetchRefundQueue(List<RefundStatus> statuses);

  Future<List<RefundableBooking>> fetchRefundableBookings(String clientId);

  Future<List<CancelledTripRefundTarget>> fetchCancelledTripsWithRefunds();

  Future<WalletTransaction> postAdjustment({
    required WalletKind kind,
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  });

  Future<WalletTransaction> reverseTransaction({
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
    required RefundSettlement settlement,
    String? reason,
    required String requestKey,
  });

  Future<TripBatchRefundResult> refundTripBatch({
    required String tripId,
    required String category,
    required String reason,
    required RefundSettlement settlement,
    required String requestKey,
  });
}
