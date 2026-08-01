import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';

abstract class SubscriptionsDatasource {
  Future<List<UserSubscription>> fetchSubscriptions();

  Future<UserSubscription> fetchSubscriptionDetails(String id);

  Future<UserSubscription> createSubscription(UserSubscription subscription);

  Future<UserSubscription> cancelSubscription(String id);

  Future<UserSubscription> renewSubscription(String id);

  /// Burns one ride off the subscription. [tripId] records which departure it
  /// was spent on, which is what lets the trip board show who has already been
  /// checked in.
  Future<UserSubscription> markRideUsed(String id, {String? tripId});

  Future<UserSubscription> confirmPayment(String id);

  Future<SubscriptionCreationOptions> fetchCreationOptions();

  /// The office's trips, for the trip filter and the trip board.
  Future<List<SubscriptionTrip>> fetchTrips();

  /// Rides already consumed, so the board can tell "eligible for this trip"
  /// apart from "already rode this trip".
  Future<List<SubscriptionRideUsage>> fetchRideUsage();
}
