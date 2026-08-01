import '../entities/user_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class MarkSubscriptionRideUsedUseCase {
  final SubscriptionsRepository _repository;

  const MarkSubscriptionRideUsedUseCase(this._repository);

  /// [tripId] attributes the ride to a specific departure. Passing it is what
  /// turns "rides used: 3" into an auditable list of which trips they were.
  Future<UserSubscription> call(String id, {String? tripId}) {
    return _repository.markRideUsed(id, tripId: tripId);
  }
}
