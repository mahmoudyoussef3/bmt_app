import '../../domain/entities/finance_payment.dart';
import '../models/finance_payment_model.dart';
import 'payment_mapper_utils.dart';

FinancePaymentModel mapSubscriptionPayment(Map<String, dynamic> row) {
  final rawId = row['id'].toString();
  final method = mapFinancePaymentMethod(
    row['payment_method']?.toString() ?? '',
  );
  final receipt = row['payment_receipt_url']?.toString();
  return FinancePaymentModel(
    id: 'subscription:$rawId',
    userName: row['customer_name']?.toString() ?? '',
    amount: '${row['total_price'] ?? 0} ج.م',
    method: method,
    paidAt: formatPaymentDate(row['created_at']?.toString()),
    status: _reviewStatus(row['payment_review_status']?.toString() ?? ''),
    user: '${row['customer_name'] ?? ''} - ${row['customer_phone'] ?? ''}',
    trip: row['route_name']?.toString() ?? '',
    packageName: row['package_name']?.toString() ?? 'اشتراك',
    referenceNumber:
        row['payment_reference']?.toString() ??
        rawId.substring(0, 8).toUpperCase(),
    receiptLabel: paymentReceiptLabel(method),
    receiptMeta: paymentReceiptMeta(receipt),
    receiptUrl: receipt,
    notes: (row['payment_notes'] as List?)?.cast<String>() ?? const [],
    history: const [],
    source: FinancePaymentSource.subscription,
  );
}

PaymentReviewStatus _reviewStatus(String status) => switch (status) {
  'accepted' => PaymentReviewStatus.accepted,
  'rejected' => PaymentReviewStatus.rejected,
  'needs_review' => PaymentReviewStatus.needsReview,
  _ => PaymentReviewStatus.pendingReview,
};

String subscriptionReviewStatusToDb(PaymentReviewStatus status) =>
    switch (status) {
      PaymentReviewStatus.accepted => 'accepted',
      PaymentReviewStatus.rejected => 'rejected',
      PaymentReviewStatus.needsReview => 'needs_review',
      PaymentReviewStatus.pendingReview => 'pending',
    };
