import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money_model.dart';

abstract class FinanceDatasource {
  Future<List<PaymentRecord>> getPayments();
  Future<List<RefundRequest>> getRefundRequests();
  Future<List<SubscriptionRecord>> getSubscriptions();
  Future<RevenueMetrics> getRevenueMetrics();

  /// The wallet-side facts behind the three statements (§7): the office's
  /// current liability, every posted wallet movement, and every settled refund
  /// with its destination.
  ///
  /// Still a read. Finance stays read-only — the 2026-08-01 boundary is not
  /// reopened, and nothing about the wallet module changes that.
  Future<WalletFinancePosition> getWalletPosition();
}
