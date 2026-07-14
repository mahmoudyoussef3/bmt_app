import 'trip_review_entry.dart';

/// What operations needs to know before reading a single review: how much
/// feedback there is, how the three dimensions score, and how many passengers
/// are unhappy enough to need a follow-up.
class ReviewsSummary {
  const ReviewsSummary({
    required this.total,
    required this.driverAverage,
    required this.vehicleAverage,
    required this.routeAverage,
    required this.needsAttentionCount,
  });

  final int total;
  final double driverAverage;
  final double vehicleAverage;
  final double routeAverage;
  final int needsAttentionCount;

  static const ReviewsSummary empty = ReviewsSummary(
    total: 0,
    driverAverage: 0,
    vehicleAverage: 0,
    routeAverage: 0,
    needsAttentionCount: 0,
  );

  factory ReviewsSummary.from(List<TripReviewEntry> reviews) {
    if (reviews.isEmpty) return empty;

    double avg(int Function(TripReviewEntry) pick) {
      final sum = reviews.fold<int>(0, (acc, r) => acc + pick(r));
      return sum / reviews.length;
    }

    return ReviewsSummary(
      total: reviews.length,
      driverAverage: avg((r) => r.driverRating),
      vehicleAverage: avg((r) => r.vehicleRating),
      routeAverage: avg((r) => r.routeRating),
      needsAttentionCount: reviews.where((r) => r.needsAttention).length,
    );
  }
}

/// A captain ranked by what passengers actually said about them.
class DriverRatingStanding {
  const DriverRatingStanding({
    required this.driverName,
    required this.average,
    required this.reviewCount,
  });

  final String driverName;
  final double average;
  final int reviewCount;

  /// Ranks captains by their average. Captains with a single review are still
  /// listed — operations wants to see a brand-new captain's first 1-star as
  /// soon as it lands, not after they clear some arbitrary threshold.
  static List<DriverRatingStanding> rank(List<TripReviewEntry> reviews) {
    final byDriver = <String, List<TripReviewEntry>>{};
    for (final review in reviews) {
      final name = review.driverName.trim();
      if (name.isEmpty) continue;
      byDriver.putIfAbsent(name, () => []).add(review);
    }

    final standings = byDriver.entries.map((entry) {
      final ratings = entry.value.map((r) => r.driverRating);
      final sum = ratings.fold<int>(0, (acc, value) => acc + value);
      return DriverRatingStanding(
        driverName: entry.key,
        average: sum / entry.value.length,
        reviewCount: entry.value.length,
      );
    }).toList();

    standings.sort((a, b) => b.average.compareTo(a.average));
    return standings;
  }
}
