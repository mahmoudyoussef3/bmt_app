import '../../domain/entities/user_subscription.dart';

abstract class SubscriptionsDatasource {
  Future<List<UserSubscription>> fetchSubscriptions();

  Future<UserSubscription> fetchSubscriptionDetails(String id);

  Future<UserSubscription> createSubscription(UserSubscription subscription);

  Future<UserSubscription> cancelSubscription(String id);

  Future<UserSubscription> renewSubscription(String id);

  Future<UserSubscription> markRideUsed(String id);

  Future<SubscriptionCreationOptions> fetchCreationOptions();
}
