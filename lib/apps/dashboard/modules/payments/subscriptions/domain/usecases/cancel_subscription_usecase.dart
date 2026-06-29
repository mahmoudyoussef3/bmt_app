import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class CancelSubscriptionUseCase {
  final SubscriptionsRepository _repository;

  const CancelSubscriptionUseCase(this._repository);

  Future<UserSubscription> call(String id) {
    return _repository.cancelSubscription(id);
  }
}
