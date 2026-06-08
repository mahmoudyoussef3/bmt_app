import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionsUseCase {
  final SubscriptionsRepository _repository;

  const GetSubscriptionsUseCase(this._repository);

  Future<List<UserSubscription>> call() {
    return _repository.getSubscriptions();
  }
}
