import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class CreateSubscriptionUseCase {
  final SubscriptionsRepository _repository;

  const CreateSubscriptionUseCase(this._repository);

  Future<UserSubscription> call(UserSubscription subscription) {
    return _repository.createSubscription(subscription);
  }
}
