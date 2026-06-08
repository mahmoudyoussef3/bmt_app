import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionDetailsUseCase {
  final SubscriptionsRepository _repository;

  const GetSubscriptionDetailsUseCase(this._repository);

  Future<UserSubscription> call(String id) {
    return _repository.getSubscriptionDetails(id);
  }
}
