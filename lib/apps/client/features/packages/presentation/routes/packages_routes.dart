/// Named routes for the Client App commute-package subscription flow.
class PackagesRoutes {
  PackagesRoutes._();

  static const subscription = '/subscription';

  /// The rider's own subscription: usage detail, not the plan catalogue.
  static const mySubscription = '/my-subscription';

  /// The path the backend writes into `notifications.action_url` when a package
  /// expires or is exhausted ("renew now").
  ///
  /// It predates [mySubscription] and never matched it, so tapping one of those
  /// notifications threw "Could not find a generator for route". Registered as
  /// an alias of [mySubscription] because production rows already carry this
  /// string — rewriting history is not worth a one-line route entry.
  static const legacyExpiryAlias = '/subscriptions';
}
