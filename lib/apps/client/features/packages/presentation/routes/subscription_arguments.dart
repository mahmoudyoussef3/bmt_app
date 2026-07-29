/// Arguments for `PackagesRoutes.subscription`.
///
/// The screen is a **catalogue**: it shows what an office sells, not a checkout.
/// A commute package is priced against a route and consumed by trips on it, so
/// buying one always happens inside the booking wizard's package step, where a
/// route, a date and a seat already exist.
///
/// An office profile passes [initialOfficeId] so the marketplace opens already
/// filtered to that seller, or [initialPackageId] to jump straight to one
/// package's detail pane instead of the filtered listing.
///
/// ### What was removed and why
///
/// This class used to carry a `bookingData` map and a `hasBookingContext` flag
/// that routed the subscribe CTA to a standalone checkout. Nothing ever supplied
/// a trip through it — the only navigations pass either nothing, an office id,
/// or `{'hasActiveSubscription': …}` from Home. That last one made the map
/// non-empty, so `hasBookingContext` read `true` and Home's "Packages" tile led
/// to a checkout with no trip, no seat and a permanently blocked pay button.
/// The flag is gone rather than repaired: there is no second checkout to route
/// to, so there is nothing for it to decide.
class SubscriptionArguments {
  const SubscriptionArguments({this.initialOfficeId, this.initialPackageId});

  factory SubscriptionArguments.fromArguments(Object? arguments) {
    if (arguments is! Map) return const SubscriptionArguments();

    final officeId = arguments['initialOfficeId']?.toString();
    final packageId = arguments['initialPackageId']?.toString();
    return SubscriptionArguments(
      initialOfficeId: (officeId != null && officeId.isNotEmpty)
          ? officeId
          : null,
      initialPackageId: (packageId != null && packageId.isNotEmpty)
          ? packageId
          : null,
    );
  }

  /// The office the marketplace should open filtered to, or `null` for the whole
  /// marketplace.
  final String? initialOfficeId;

  /// The package whose detail pane the marketplace should open directly to,
  /// or `null` to land on the listing as usual.
  final String? initialPackageId;
}
