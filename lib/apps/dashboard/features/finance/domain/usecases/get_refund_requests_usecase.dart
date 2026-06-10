import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetRefundRequestsUseCase {
  final FinanceRepository _repository;

  const GetRefundRequestsUseCase(this._repository);

  Future<List<RefundRequest>> call() => _repository.getRefundRequests();
}
