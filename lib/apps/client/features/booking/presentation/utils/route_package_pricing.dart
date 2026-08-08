import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/pricing/trip_pricing_resolver.dart';

/// What a package costs on this corridor, before the rider has narrowed it to
/// a stop pair.
///
/// A package is priced per pickup → dropoff pair, and Route Details is shown
/// before either is chosen — so there is no single correct figure yet. The
/// cheapest configured pair is the only honest one to lead with: it is a real
/// price the rider can actually pay on this route, and it can only go up from
/// there, which is why the section labels it "from" and says out loud that the
/// exact amount is settled at booking.
///
/// Returns null when no departure on the route prices this package's shape.
/// The catalogue's flat `price` is deliberately *not* used as a fallback: it is
/// the wizard's last resort for an unconfigured pair, not a figure any rider
/// browsing a corridor would actually be charged.
double? routePackageFromPrice(RouteOptionData route, PackagePlan plan) {
  double? cheapest;

  for (final trip in route.availableTrips) {
    for (final row in trip.stopPricing) {
      if (!row.isActive) continue;
      final tier = TripPricingResolver.tierPriceOf(
        row,
        plan.durationDays,
        plan.rideCount,
      );
      if (tier == null || tier <= 0) continue;
      if (cheapest == null || tier < cheapest) cheapest = tier;
    }
  }

  return cheapest;
}

/// The regular one-time fare of the same cheapest pair, so a plan can be shown
/// against what its rides would cost bought separately. Null when the route
/// publishes no active per-pair fare.
double? routeCheapestRideFare(RouteOptionData route) {
  double? cheapest;

  for (final trip in route.availableTrips) {
    for (final row in trip.stopPricing) {
      if (!row.isActive || row.oneTimePrice <= 0) continue;
      if (cheapest == null || row.oneTimePrice < cheapest) {
        cheapest = row.oneTimePrice;
      }
    }
  }

  return cheapest;
}
