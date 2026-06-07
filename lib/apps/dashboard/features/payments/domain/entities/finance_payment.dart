enum PaymentReviewStatus {
  pendingReview('بانتظار المراجعة'),
  accepted('مقبول'),
  rejected('مرفوض'),
  needsReview('محتاج مراجعة');

  final String label;

  const PaymentReviewStatus(this.label);
}

enum FinancePaymentMethod {
  card('بطاقة'),
  wallet('محفظة'),
  bankTransfer('تحويل بنكي'),
  cash('كاش');

  final String label;

  const FinancePaymentMethod(this.label);
}

class FinancePayment {
  final String id;
  final String userName;
  final String amount;
  final FinancePaymentMethod method;
  final String paidAt;
  final PaymentReviewStatus status;
  final String user;
  final String trip;
  final String packageName;
  final String referenceNumber;
  final String receiptLabel;
  final String receiptMeta;
  final List<String> notes;
  final List<PaymentHistoryItem> history;

  const FinancePayment({
    required this.id,
    required this.userName,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.status,
    required this.user,
    required this.trip,
    required this.packageName,
    required this.referenceNumber,
    required this.receiptLabel,
    required this.receiptMeta,
    required this.notes,
    required this.history,
  });

  FinancePayment copyWith({
    PaymentReviewStatus? status,
    List<String>? notes,
    List<PaymentHistoryItem>? history,
  }) {
    return FinancePayment(
      id: id,
      userName: userName,
      amount: amount,
      method: method,
      paidAt: paidAt,
      status: status ?? this.status,
      user: user,
      trip: trip,
      packageName: packageName,
      referenceNumber: referenceNumber,
      receiptLabel: receiptLabel,
      receiptMeta: receiptMeta,
      notes: notes ?? this.notes,
      history: history ?? this.history,
    );
  }
}

class PaymentHistoryItem {
  final String title;
  final String time;
  final String description;

  const PaymentHistoryItem({
    required this.title,
    required this.time,
    required this.description,
  });
}
