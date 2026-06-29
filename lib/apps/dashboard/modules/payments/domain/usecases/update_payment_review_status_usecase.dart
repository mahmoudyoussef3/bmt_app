import '../entities/finance_payment.dart';
import '../repositories/payments_repository.dart';

class UpdatePaymentReviewStatusUseCase {
  final PaymentsRepository _repository;

  const UpdatePaymentReviewStatusUseCase(this._repository);

  Future<FinancePayment> call(String paymentId, PaymentReviewStatus status) {
    return _repository.updateStatus(paymentId, status);
  }
}
