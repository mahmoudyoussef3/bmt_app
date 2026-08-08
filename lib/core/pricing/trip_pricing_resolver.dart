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

  /// The package-tier fare for the pair, bucketed by the package's
  /// [durationDays] / [rideCount] — NOT by `transport_packages.package_type`
  /// text (values like `just_go`, `work_week`, `two_work_weeks` don't line
  /// up with trip_pricing's tier column names, and package_type is
  /// free-form admin-editable text with no fixed vocabulary). This mirrors
  /// the identical bucketing in the `confirm_seat_booking_v2` Supabase RPC
  /// (see migration `20260710090000_authoritative_booking_pricing.sql`) so
  /// the price shown here is always what the server will actually charge.
  /// Returns null when the pair has no row, or the package's shape has no
  /// trip_pricing equivalent (e.g. a same-day round trip: durationDays=1
  /// with rideCount>1) — callers should fall back to the catalog price.
  static double? packageFareFor(
    List<TripStopPairPrice> pricing,
    String? fromPointId,
    String? toPointId,
    int durationDays,
    int rideCount,
  ) {
    final row = forPair(pricing, fromPointId, toPointId);
    if (row == null) return null;
    return tierPriceOf(row, durationDays, rideCount);
  }

  /// The tier column of one `trip_pricing` row that a package of this shape is
  /// charged from. Split out of [packageFareFor] so a surface that quotes a
  /// package before the rider has picked their stops — Route Details' "from"
  /// price — buckets it by the same rule the booking RPC will, instead of
  /// re-deriving the thresholds and drifting from them.
  static double? tierPriceOf(
    TripStopPairPrice row,
    int durationDays,
    int rideCount,
  ) {
    if (durationDays <= 1 && rideCount == 1) return row.oneTimePrice;
    if (durationDays >= 2 && durationDays <= 6) return row.fiveDaysPrice;
    if (durationDays >= 7 && durationDays <= 15) return row.tenDaysPrice;
    if (durationDays >= 16 && durationDays <= 60) return row.monthlyPrice;
    if (durationDays > 60) return row.threeMonthsPrice;
    return null;
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
