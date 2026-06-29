import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetPaymentsUseCase {
  final FinanceRepository _repository;

  const GetPaymentsUseCase(this._repository);

  Future<List<PaymentRecord>> call() => _repository.getPayments();
}
