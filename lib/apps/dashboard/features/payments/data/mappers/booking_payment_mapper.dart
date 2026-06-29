import '../../domain/entities/finance_payment.dart';
import '../models/finance_payment_model.dart';
import 'payment_mapper_utils.dart';

FinancePaymentModel mapBookingPayment(Map<String, dynamic> row) {
  final details = row['payment_details'] as Map<String, dynamic>? ?? {};
  final trip = row['trip'] as Map<String, dynamic>? ?? {};
  final route = trip['route'] as Map<String, dynamic>? ?? {};
  final method = mapFinancePaymentMethod(details['method']?.toString() ?? '');
  final receiptUrl = row['payment_receipt_url'] as String?;
  final timeline = (row['timeline'] as List?) ?? [];
  final id = row['id'].toString();

  return FinancePaymentModel(
    id: id,
    userName: row['passenger_name']?.toString() ?? '',
    amount: '${details['amount'] ?? 0} ج.م',
    method: method,
    paidAt: formatPaymentDate(row['created_at']?.toString()),
    status: _bookingStatus(row['status']?.toString() ?? ''),
    user: '${row['passenger_name'] ?? ''} - ${row['phone'] ?? ''}',
    trip: _tripLabel(trip, route),
    packageName: 'رحلة مفردة',
    referenceNumber:
        details['reference']?.toString() ?? id.substring(0, 8).toUpperCase(),
    receiptLabel: paymentReceiptLabel(method),
    receiptMeta: paymentReceiptMeta(receiptUrl),
    receiptUrl: receiptUrl,
    notes: (row['notes'] as List?)?.cast<String>() ?? const [],
    history: timeline.map(_historyItem).toList(),
    source: FinancePaymentSource.booking,
  );
}

PaymentReviewStatus _bookingStatus(String value) => switch (value) {
  'requestReupload' => PaymentReviewStatus.needsReview,
  'approved' || 'confirmed' => PaymentReviewStatus.accepted,
  'rejected' => PaymentReviewStatus.rejected,
  _ => PaymentReviewStatus.pendingReview,
};

String _tripLabel(Map<String, dynamic> trip, Map<String, dynamic> route) {
  final name = route['name']?.toString() ?? '';
  final date = trip['trip_date']?.toString() ?? '';
  final time = trip['departure_time']?.toString() ?? '';
  return name.isEmpty ? date : '$name  $date  $time';
}

PaymentHistoryItem _historyItem(dynamic value) {
  final item = value as Map<String, dynamic>;
  return PaymentHistoryItem(
    title: (item['action'] ?? item['title'] ?? '').toString(),
    time: (item['timestamp'] ?? item['time'] ?? '').toString(),
    description: (item['actor'] ?? item['description'] ?? '').toString(),
  );
}
