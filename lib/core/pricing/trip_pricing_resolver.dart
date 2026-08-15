import 'trip_stop_pair_price.dart';

/// Resolves the Dashboard-configured fare for the *exact* pickup -> dropoff
/// stop pair a rider selected, instead of an aggregate ("cheapest") or
/// arbitrary ("first row") price across the whole trip.
///
/// Shared by regular-fare resolution and package-tier resolution (client
/// booking wizard) so both read the same `trip_pricing` row — see
/// CLAUDE.md section 6 (shared logic belongs in `core/`).
class TripPricingResolver {
  const TripPricingResolver._();

  /// The `trip_pricing` row matching [fromPointId] -> [toPointId] exactly.
  static TripStopPairPrice? forPair(
    List<TripStopPairPrice> pricing,
    String? fromPointId,
    String? toPointId,
  ) {
    if (fromPointId == null || fromPointId.isEmpty) return null;
    if (toPointId == null || toPointId.isEmpty) return null;
    for (final row in pricing) {
      if (row.isActive && row.matchesPair(fromPointId, toPointId)) {
        return row;
      }
    }
    return null;
  }

  /// The regular one-time fare for the pair, or null if unconfigured.
  static double? oneTimeFareFor(
    List<TripStopPairPrice> pricing,
    String? fromPointId,
    String? toPointId,
  ) {
    return forPair(pricing, fromPointId, toPointId)?.oneTimePrice;
  }

  /// The package fare for the pair. A single-ride package (`durationDays <=
  /// 1 && rideCount == 1`) resolves to the pair's own [TripStopPairPrice.
  /// oneTimePrice] — every other package resolves to its own price, set
  /// directly by the office (`trip_package_prices`). Mirrors the exact
  /// branch `confirm_seat_booking_v2` takes (see migration
  /// `20260815091000_per_package_trip_pricing.sql`) so the price shown here
  /// is always what the server will actually charge. Returns null when the
  /// pair has no row, or the office hasn't priced this package on this pair
  /// yet — callers should fall back to the catalog price.
  static double? packageFareFor(
    List<TripStopPairPrice> pricing,
    String? fromPointId,
    String? toPointId,
    String packageId,
    int durationDays,
    int rideCount,
  ) {
    final row = forPair(pricing, fromPointId, toPointId);
    if (row == null) return null;
    return tierPriceOf(row, packageId, durationDays, rideCount);
  }

  /// The package's price on one `trip_pricing` row. Split out of
  /// [packageFareFor] so a surface that quotes a package before the rider
  /// has picked their stops — Route Details' "from" price — can look it up
  /// the same way.
  static double? tierPriceOf(
    TripStopPairPrice row,
    String packageId,
    int durationDays,
    int rideCount,
  ) {
    if (durationDays <= 1 && rideCount == 1) {
      return row.oneTimePrice > 0 ? row.oneTimePrice : null;
    }
    final price = row.packagePrices[packageId];
    return price != null && price > 0 ? price : null;
  }

  /// Extracts the numeric amount from a formatted price label such as
  /// `"EGP 20"` or `"20"`. Used only as a last-resort fallback when no
  /// `trip_pricing` row matches — plain `double.tryParse` fails on the
  /// currency-prefixed label and silently collapses to 0.
  static double parsePriceLabel(String label) {
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(label);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!) ?? 0;
  }
}
