import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionCreationOptionsUseCase {
  final SubscriptionsRepository _repository;

  const GetSubscriptionCreationOptionsUseCase(this._repository);

  Future<SubscriptionCreationOptions> call() {
    return _repository.getCreationOptions();
  }
}
