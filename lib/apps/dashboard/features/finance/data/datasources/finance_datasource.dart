import '../../domain/entities/finance_entities.dart';

abstract class FinanceDatasource {
  Future<List<PaymentRecord>> getPayments();
  Future<List<ReceiptReview>> getReceiptReviews();
  Future<List<RefundRequest>> getRefundRequests();
  Future<List<SubscriptionRecord>> getSubscriptions();
  Future<RevenueMetrics> getRevenueMetrics();
  Future<List<RevenueTrendPoint>> getRevenueTrend();
  Future<void> reviewReceipt(
    String id,
    ReceiptReviewStatus action, {
    String? notes,
  });
  Future<void> processRefund(String id, RefundStatus action);
  Future<void> cancelSubscription(String id);
}
