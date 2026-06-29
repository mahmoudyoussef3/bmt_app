import '../entities/finance_payment.dart';
import '../repositories/payments_repository.dart';

class GetFinancePaymentsUseCase {
  final PaymentsRepository _repository;

  const GetFinancePaymentsUseCase(this._repository);

  Future<List<FinancePayment>> call() {
    return _repository.getPayments();
  }
}
