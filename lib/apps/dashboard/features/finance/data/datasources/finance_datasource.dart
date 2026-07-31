import '../../domain/entities/finance_entities.dart';

abstract class FinanceDatasource {
  Future<List<PaymentRecord>> getPayments();
  Future<List<RefundRequest>> getRefundRequests();
  Future<List<SubscriptionRecord>> getSubscriptions();
  Future<RevenueMetrics> getRevenueMetrics();
}
