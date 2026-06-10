import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetFinanceSubscriptionsUseCase {
  final FinanceRepository _repository;

  const GetFinanceSubscriptionsUseCase(this._repository);

  Future<List<SubscriptionRecord>> call() => _repository.getSubscriptions();
}
