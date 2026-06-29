import '../entities/finance_payment.dart';
import '../repositories/payments_repository.dart';

class AddPaymentNoteUseCase {
  final PaymentsRepository _repository;

  const AddPaymentNoteUseCase(this._repository);

  Future<FinancePayment> call(String paymentId, String note) {
    return _repository.addNote(paymentId, note);
  }
}
