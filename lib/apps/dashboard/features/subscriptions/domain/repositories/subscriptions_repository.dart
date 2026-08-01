import '../entities/subscription_trip.dart';
import '../entities/user_subscription.dart';

abstract class SubscriptionsRepository {
  Future<List<UserSubscription>> getSubscriptions();

  Future<UserSubscription> getSubscriptionDetails(String id);

  Future<UserSubscription> createSubscription(UserSubscription subscription);

  Future<UserSubscription> cancelSubscription(String id);

  Future<UserSubscription> renewSubscription(String id);

  Future<UserSubscription> markRideUsed(String id, {String? tripId});

  Future<UserSubscription> confirmPayment(String id);

  Future<SubscriptionCreationOptions> getCreationOptions();

  Future<List<SubscriptionTrip>> getTrips();

  Future<List<SubscriptionRideUsage>> getRideUsage();
}
