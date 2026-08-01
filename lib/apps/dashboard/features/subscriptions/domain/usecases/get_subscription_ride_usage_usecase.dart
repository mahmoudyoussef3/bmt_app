import '../entities/subscription_trip.dart';
import '../repositories/subscriptions_repository.dart';

/// The ledger of rides already consumed, so the trip board can separate
/// subscribers who still need checking in from those already recorded.
class GetSubscriptionRideUsageUseCase {
  final SubscriptionsRepository _repository;

  const GetSubscriptionRideUsageUseCase(this._repository);

  Future<List<SubscriptionRideUsage>> call() {
    return _repository.getRideUsage();
  }
}
