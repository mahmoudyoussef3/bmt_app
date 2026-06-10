import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class ProcessRefundUseCase {
  final FinanceRepository _repository;

  const ProcessRefundUseCase(this._repository);

  Future<void> call(String id, RefundStatus action) =>
      _repository.processRefund(id, action);
}
