import '../repositories/finance_repository.dart';

class CancelFinanceSubscriptionUseCase {
  final FinanceRepository _repository;

  const CancelFinanceSubscriptionUseCase(this._repository);

  Future<void> call(String id) => _repository.cancelSubscription(id);
}
