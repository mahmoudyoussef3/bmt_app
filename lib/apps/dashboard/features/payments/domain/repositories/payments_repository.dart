import '../entities/finance_payment.dart';

abstract class PaymentsRepository {
  Future<List<FinancePayment>> getPayments();

  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  );

  Future<FinancePayment> addNote(String paymentId, String note);
}
