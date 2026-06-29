import '../../domain/entities/finance_entities.dart';

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.id,
    required super.clientName,
    required super.tripCode,
    required super.amount,
    required super.paymentMethod,
    required super.status,
    required super.date,
  });
}

class ReceiptReviewModel extends ReceiptReview {
  const ReceiptReviewModel({
    required super.id,
    required super.transactionId,
    required super.clientName,
    required super.tripCode,
    required super.amount,
    required super.date,
    required super.receiptUrl,
    required super.status,
    super.notes,
    required super.history,
  });
}

class RefundRequestModel extends RefundRequest {
  const RefundRequestModel({
    required super.id,
    required super.transactionId,
    required super.clientName,
    required super.amount,
    required super.date,
    required super.status,
    required super.reason,
    required super.history,
  });
}

class SubscriptionRecordModel extends SubscriptionRecord {
  const SubscriptionRecordModel({
    required super.id,
    required super.clientName,
    required super.packageName,
    required super.amount,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.remainingRides,
  });
}
