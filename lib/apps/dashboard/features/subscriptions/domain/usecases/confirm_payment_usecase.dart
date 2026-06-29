import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class ConfirmPaymentUseCase {
  final SubscriptionsRepository _repository;

  const ConfirmPaymentUseCase(this._repository);

  Future<UserSubscription> call(String id) {
    return _repository.confirmPayment(id);
  }
}
