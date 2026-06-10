import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/mock_finance_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final MockFinanceDatasource _datasource;

  const FinanceRepositoryImpl(this._datasource);

  @override
  Future<List<PaymentRecord>> getPayments() async {
    return _datasource.getPayments();
  }

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async {
    return _datasource.getReceiptReviews();
  }

  @override
  Future<List<RefundRequest>> getRefundRequests() async {
    return _datasource.getRefundRequests();
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    return _datasource.getSubscriptions();
  }

  @override
  Future<RevenueMetrics> getRevenueMetrics() async {
    return _datasource.getRevenueMetrics();
  }

  @override
  Future<void> reviewReceipt(String id, ReceiptReviewStatus action, {String? notes}) async {
    _datasource.reviewReceipt(id, action, notes: notes);
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    _datasource.processRefund(id, action);
  }

  @override
  Future<void> cancelSubscription(String id) async {
    _datasource.cancelSubscription(id);
  }
}
