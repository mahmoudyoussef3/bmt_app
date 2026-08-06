import '../entities/finance_analytics.dart';
import '../entities/finance_entities.dart';
import '../entities/finance_money_model.dart';

/// Read-only by design. Deciding on a receipt, approving a refund or cancelling
/// a subscription are Bookings / Subscriptions operations — Finance reports the
/// money those decisions produced, it does not make them.
abstract class FinanceRepository {
  Future<List<PaymentRecord>> getPayments();
  Future<List<RefundRequest>> getRefundRequests();
  Future<List<SubscriptionRecord>> getSubscriptions();
  Future<RevenueMetrics> getRevenueMetrics();

  /// The wallet-side facts behind the three statements (§7). A read: the wallet
  /// module owns every decision that moves this data.
  Future<WalletFinancePosition> getWalletPosition();

  /// Writes [statement] to a downloadable file and returns the file name.
  /// The only "write" in the module, and it writes to disk, not to the database.
  Future<String> exportStatement(FinanceStatement statement, String format);
}
