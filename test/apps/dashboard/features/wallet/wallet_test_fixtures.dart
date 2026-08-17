import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/refund_request.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_summary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/repositories/wallet_repository.dart';

final walletNow = DateTime(2026, 8, 6, 12);

WalletOverview overviewFixture({
  double outstanding = 12450,
  int pendingRefunds = 3,
}) => WalletOverview(
  outstandingBalance: outstanding,
  walletCount: 8,
  fundedWalletCount: 5,
  frozenCount: 0,
  cashbackTotal: 3200,
  creditTotal: 640,
  debitTotal: 120,
  refundTotal: 8100,
  refundWalletTotal: 6000,
  pendingRefundCount: pendingRefunds,
  pendingRefundAmount: 420,
  generatedAt: walletNow,
);

WalletDirectoryEntry directoryEntryFixture({
  String id = 'c1',
  String name = 'أحمد محمود',
  double balance = 250,
  int pendingRefunds = 0,
  WalletStatus status = WalletStatus.active,
}) => WalletDirectoryEntry(
  clientId: id,
  fullName: name,
  phone: '0100000000',
  balance: balance,
  walletStatus: status,
  entryCount: 12,
  pendingRefunds: pendingRefunds,
  lastActivityAt: walletNow.subtract(const Duration(days: 1)),
);

WalletTransaction entryFixture({
  String id = 't1',
  int seq = 12,
  WalletKind kind = WalletKind.refund,
  double amount = 200,
  double balanceAfter = 250,
  WalletEntryStatus status = WalletEntryStatus.posted,
  String? clientName,
}) => WalletTransaction(
  id: id,
  seq: seq,
  kind: kind,
  category: kind == WalletKind.refund ? 'trip_cancelled' : 'promotion',
  source: WalletSource.dashboard,
  amount: amount,
  balanceBefore: balanceAfter - amount,
  balanceAfter: balanceAfter,
  status: status,
  reason: 'اختبار سجل المحفظة',
  performedByName: 'مشغّل الاختبار',
  createdAt: walletNow,
  clientId: 'c1',
  clientName: clientName,
  bookingNumber: '1042',
);

RefundRequest refundFixture({
  String id = 'r1',
  RefundStatus status = RefundStatus.pending,
  double amount = 120,
  String? clientId = 'c1',
}) => RefundRequest(
  id: id,
  clientId: clientId,
  clientName: 'أحمد محمود',
  bookingId: 'b1',
  bookingNumber: '1042',
  amount: amount,
  currency: 'EGP',
  status: status,
  category: 'trip_cancelled',
  reason: 'إلغاء الرحلة',
  source: 'client',
  createdAt: walletNow,
);

WalletSummary summaryFixture({
  double balance = 250,
  WalletStatus status = WalletStatus.active,
  List<RefundRequest>? pendingRefunds,
  List<WalletTransaction>? entries,
}) => WalletSummary(
  customer: const WalletCustomer(
    id: 'c1',
    fullName: 'أحمد محمود',
    phone: '0100000000',
  ),
  wallet: Wallet(
    exists: true,
    id: 'w1',
    balance: balance,
    availableBalance: balance,
    status: status,
    frozenReason: status == WalletStatus.frozen ? 'اشتباه' : null,
    entryCount: 12,
    lifetimeCredited: 300,
    lifetimeDebited: 50,
    lastSeq: 12,
  ),
  totalsByKind: const {
    WalletKind.refund: 200,
    WalletKind.cashback: 100,
    WalletKind.manualDebit: 50,
  },
  pendingRefunds: pendingRefunds ?? const [],
  entries: entries ?? [entryFixture()],
);

/// A repository that answers from fixtures and records every write it is asked
/// to perform, so a test can assert what a screen or cubit actually did.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({
    WalletOverview? overview,
    WalletDirectoryPage? directory,
    WalletSummary? summary,
    this.refundQueue = const [],
  }) : overview = overview ?? overviewFixture(),
       directory =
           directory ??
           WalletDirectoryPage(total: 1, rows: [directoryEntryFixture()]),
       summary = summary ?? summaryFixture();

  WalletOverview overview;
  WalletDirectoryPage directory;
  WalletSummary summary;
  List<RefundRequest> refundQueue;

  final List<String> calls = [];
  String? lastSearch;
  bool failReads = false;
  String? failWritesWith;

  @override
  Future<WalletOverview> getOverview() async {
    if (failReads) throw Exception('تعذر تحميل الملخص');
    calls.add('overview');
    return overview;
  }

  @override
  Future<WalletDirectoryPage> getDirectory({
    String? search,
    int limit = 60,
    int offset = 0,
  }) async {
    if (failReads) throw Exception('تعذر تحميل العملاء');
    calls.add('directory');
    lastSearch = search;
    return directory;
  }

  @override
  Future<WalletSummary> getSummary(String clientId) async {
    if (failReads) throw Exception('تعذر تحميل المحفظة');
    calls.add('summary');
    return summary;
  }

  @override
  Future<WalletLedgerPage> getLedger({
    required WalletLedgerFilters filters,
    int limit = 100,
    int offset = 0,
  }) async {
    calls.add('ledger');
    return WalletLedgerPage(
      total: 1,
      sumCredit: 200,
      sumDebit: 0,
      rows: [entryFixture(clientName: 'أحمد محمود')],
    );
  }

  @override
  Future<List<RefundRequest>> getRefundQueue({
    List<RefundStatus> statuses = const [
      RefundStatus.pending,
      RefundStatus.approved,
    ],
  }) async {
    calls.add('queue');
    return refundQueue;
  }

  @override
  Future<List<RefundableBooking>> getRefundableBookings(String clientId) async {
    calls.add('refundableBookings');
    return const [
      RefundableBooking(
        bookingId: 'b1',
        bookingNumber: '1042',
        status: 'confirmed',
        paidAmount: 300,
        refundableAmount: 300,
        route: 'القاهرة - الإسكندرية',
      ),
    ];
  }

  @override
  Future<List<CancelledTripRefundTarget>> getCancelledTripsWithRefunds() async {
    calls.add('cancelledTrips');
    return const [
      CancelledTripRefundTarget(
        tripId: 'trip-1',
        pendingBookings: 14,
        refundableAmount: 2100,
        routeName: 'القاهرة - أسيوط',
      ),
    ];
  }

  @override
  Future<WalletTransaction> grantCashback({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async => _write('cashback', amount);

  @override
  Future<WalletTransaction> credit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async => _write('credit', amount);

  @override
  Future<WalletTransaction> debit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async => _write('debit', -amount);

  @override
  Future<WalletTransaction> reverse({
    required String transactionId,
    required String reason,
    required String category,
    required String requestKey,
  }) async => _write('reverse', -1);

  @override
  Future<Wallet> setWalletStatus({
    required String clientId,
    required WalletStatus status,
    required String reason,
  }) async {
    if (failWritesWith != null) throw Exception(failWritesWith);
    calls.add('setStatus');
    return summary.wallet;
  }

  @override
  Future<WalletChainVerification> verifyChain(String clientId) async {
    calls.add('verifyChain');
    return const WalletChainVerification(
      verified: true,
      entries: 12,
      ledgerBalance: 250,
      cachedBalance: 250,
      headHash: 'abcdef0123456789',
    );
  }

  @override
  Future<String> exportStatement({
    required List<WalletTransaction> rows,
    required WalletOverview overview,
  }) async {
    calls.add('exportStatement');
    return 'wallet_statement.csv';
  }

  @override
  Future<RefundRequest> createRefund({
    required String bookingId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
  }) async {
    if (failWritesWith != null) throw Exception(failWritesWith);
    calls.add('createRefund');
    return refundFixture(amount: amount, status: RefundStatus.settled);
  }

  @override
  Future<RefundRequest> decideRefund({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement = RefundSettlement.wallet,
    String? reason,
    required String requestKey,
  }) async {
    if (failWritesWith != null) throw Exception(failWritesWith);
    calls.add('decideRefund');
    return refundFixture(
      amount: approvedAmount ?? 120,
      status: approve ? RefundStatus.settled : RefundStatus.rejected,
    );
  }

  @override
  Future<TripBatchRefundResult> refundTripBatch({
    required String tripId,
    required String category,
    required String reason,
    required RefundSettlement settlement,
    required String requestKey,
  }) async {
    if (failWritesWith != null) throw Exception(failWritesWith);
    calls.add('refundTripBatch');
    return const TripBatchRefundResult(
      batchId: 'batch-1',
      tripId: 'trip-1',
      refunded: 12,
      skipped: 2,
      totalAmount: 1800,
    );
  }

  WalletTransaction _write(String name, double amount) {
    if (failWritesWith != null) throw Exception(failWritesWith);
    calls.add(name);
    return entryFixture(amount: amount, balanceAfter: 250 + amount);
  }
}
