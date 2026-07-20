import '../../domain/entities/my_subscription.dart';

sealed class MySubscriptionState {
  const MySubscriptionState();
}

class MySubscriptionLoading extends MySubscriptionState {
  const MySubscriptionLoading();
}

class MySubscriptionLoaded extends MySubscriptionState {
  const MySubscriptionLoaded(this.subscription);

  final MySubscription subscription;
}

/// The rider has no active subscription. Reachable only if it lapsed between
/// Home loading and the tap landing here, since Home only offers this route
/// when one exists.
class MySubscriptionEmpty extends MySubscriptionState {
  const MySubscriptionEmpty();
}

class MySubscriptionError extends MySubscriptionState {
  const MySubscriptionError(this.message);

  final String message;
}
