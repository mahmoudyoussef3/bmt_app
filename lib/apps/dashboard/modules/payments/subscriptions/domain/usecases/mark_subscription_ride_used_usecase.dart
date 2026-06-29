import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class MarkSubscriptionRideUsedUseCase {
  final SubscriptionsRepository _repository;

  const MarkSubscriptionRideUsedUseCase(this._repository);

  Future<UserSubscription> call(String id) {
    return _repository.markRideUsed(id);
  }
}
