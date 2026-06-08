import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class RenewSubscriptionUseCase {
  final SubscriptionsRepository _repository;

  const RenewSubscriptionUseCase(this._repository);

  Future<UserSubscription> call(String id) {
    return _repository.renewSubscription(id);
  }
}
