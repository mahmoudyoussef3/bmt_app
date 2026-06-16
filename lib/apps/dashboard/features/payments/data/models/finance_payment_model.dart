import '../../domain/entities/finance_payment.dart';

class FinancePaymentModel extends FinancePayment {
  const FinancePaymentModel({
    required super.id,
    required super.userName,
    required super.amount,
    required super.method,
    required super.paidAt,
    required super.status,
    required super.user,
    required super.trip,
    required super.packageName,
    required super.referenceNumber,
    required super.receiptLabel,
    required super.receiptMeta,
    super.receiptUrl,
    required super.notes,
    required super.history,
  });

  factory FinancePaymentModel.fromEntity(FinancePayment payment) {
    return FinancePaymentModel(
      id: payment.id,
      userName: payment.userName,
      amount: payment.amount,
      method: payment.method,
      paidAt: payment.paidAt,
      status: payment.status,
      user: payment.user,
      trip: payment.trip,
      packageName: payment.packageName,
      referenceNumber: payment.referenceNumber,
      receiptLabel: payment.receiptLabel,
      receiptMeta: payment.receiptMeta,
      receiptUrl: payment.receiptUrl,
      notes: payment.notes,
      history: payment.history,
    );
  }
}
