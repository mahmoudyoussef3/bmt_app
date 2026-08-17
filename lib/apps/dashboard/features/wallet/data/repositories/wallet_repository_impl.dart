import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_datasource.dart';
import '../services/wallet_statement_export_service.dart';

/// Thin by design.
///
/// There is no mapping left to do here — the datasource already returns domain
/// entities, because the RPCs return one document per surface rather than raw
/// table rows, and inventing a second DTO layer over a shape that is already the
/// screen's shape would be ceremony. What this class does own is the *filter
/// serialisation boundary*: [WalletLedgerFilters] is a domain object, and its
/// jsonb form is a transport detail that stops here.
class WalletRepositoryImpl implements WalletRepository {
  final WalletDatasource _datasource;

  const WalletRepositoryImpl(this._datasource);

  @override
  Future<String> exportStatement({
    required List<WalletTransaction> rows,
    required WalletOverview overview,
  }) => WalletStatementExportService.export(rows: rows, overview: overview);

  @override
  Future<WalletOverview> getOverview() => _datasource.fetchOverview();

  @override
  Future<WalletDirectoryPage> getDirectory({
    String? search,
    int limit = 60,
    int offset = 0,
  }) => _datasource.fetchDirectory(search: search, limit: limit, offset: offset);

  @override
  Future<WalletSummary> getSummary(String clientId) =>
      _datasource.fetchSummary(clientId);

  @override
  Future<WalletLedgerPage> getLedger({
    required WalletLedgerFilters filters,
    int limit = 100,
    int offset = 0,
  }) => _datasource.fetchLedger(
    filters: filters.toJson(),
    limit: limit,
    offset: offset,
  );

  @override
  Future<List<RefundRequest>> getRefundQueue({
    List<RefundStatus> statuses = const [
      RefundStatus.pending,
      RefundStatus.approved,
    ],
  }) => _datasource.fetchRefundQueue(statuses);

  @override
  Future<List<RefundableBooking>> getRefundableBookings(String clientId) =>
      _datasource.fetchRefundableBookings(clientId);

  @override
  Future<List<CancelledTripRefundTarget>> getCancelledTripsWithRefunds() =>
      _datasource.fetchCancelledTripsWithRefunds();

  @override
  Future<WalletTransaction> grantCashback({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) => _datasource.postAdjustment(
    kind: WalletKind.cashback,
    clientId: clientId,
    amount: amount,
    category: category,
    reason: reason,
    notes: notes,
    requestKey: requestKey,
  );

  @override
  Future<WalletTransaction> credit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) => _datasource.postAdjustment(
    kind: WalletKind.manualCredit,
    clientId: clientId,
    amount: amount,
    category: category,
    reason: reason,
    notes: notes,
    requestKey: requestKey,
  );

  @override
  Future<WalletTransaction> debit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) => _datasource.postAdjustment(
    kind: WalletKind.manualDebit,
    clientId: clientId,
    amount: amount,
    category: category,
    reason: reason,
    notes: notes,
    requestKey: requestKey,
  );

  @override
  Future<WalletTransaction> reverse({
    required String transactionId,
    required String reason,
    required String category,
    required String requestKey,
  }) => _datasource.reverseTransaction(
    transactionId: transactionId,
    reason: reason,
    category: category,
    requestKey: requestKey,
  );

  @override
  Future<Wallet> setWalletStatus({
    required String clientId,
    required WalletStatus status,
    required String reason,
  }) => _datasource.setWalletStatus(
    clientId: clientId,
    status: status,
    reason: reason,
  );

  @override
  Future<WalletChainVerification> verifyChain(String clientId) =>
      _datasource.verifyChain(clientId);

  @override
  Future<RefundRequest> createRefund({
    required String bookingId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
  }) => _datasource.createRefund(
    bookingId: bookingId,
    amount: amount,
    category: category,
    reason: reason,
    notes: notes,
    settlement: settlement,
    requestKey: requestKey,
  );

  @override
  Future<RefundRequest> decideRefund({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement = RefundSettlement.wallet,
    String? reason,
    required String requestKey,
  }) => _datasource.decideRefund(
    refundId: refundId,
    approve: approve,
    approvedAmount: approvedAmount,
    settlement: settlement,
    reason: reason,
    requestKey: requestKey,
  );

  @override
  Future<TripBatchRefundResult> refundTripBatch({
    required String tripId,
    required String category,
    required String reason,
    required RefundSettlement settlement,
    required String requestKey,
  }) => _datasource.refundTripBatch(
    tripId: tripId,
    category: category,
    reason: reason,
    settlement: settlement,
    requestKey: requestKey,
  );
}
