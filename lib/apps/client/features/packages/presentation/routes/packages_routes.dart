/// Named routes for the Client App commute-package subscription flow.
///
/// There is deliberately no plan-catalogue route. A standalone marketplace
/// listed the same plans an office profile already lists and the booking wizard
/// already sells, so it was removed: packages are discovered on an office
/// profile and bought in the wizard's package step, which is the only place a
/// route exists to price them against.
class PackagesRoutes {
  PackagesRoutes._();

  /// The rider's own subscription: usage detail, not a plan catalogue.
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
