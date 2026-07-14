import 'dart:math' as math;

/// One passenger's review of one completed trip, as operations sees it.
///
/// This is the only place in the platform where an individual review — the
/// stars AND the written feedback — is readable. Passengers see aggregates;
/// captains see their own average; operations sees the whole story.
class TripReviewEntry {
  const TripReviewEntry({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.clientName,
    required this.driverName,
    required this.vehicleName,
    required this.routeLabel,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.comment,
    required this.createdAt,
    this.driverId,
  });

  final String id;
  final String bookingId;
  final String bookingNumber;
  final String clientName;
  final String driverName;
  final String vehicleName;
  final String routeLabel;
  final String? driverId;

  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final String comment;
  final DateTime createdAt;

  double get averageRating =>
      (driverRating + vehicleRating + routeRating) / 3;

  /// The worst of the three — what decides whether this needs a human. A trip
  /// with a 5-star captain and a 1-star vehicle averages "fine" and is not.
  int get lowestRating =>
      math.min(driverRating, math.min(vehicleRating, routeRating));

  /// Anything at 2 stars or below on any dimension is a complaint in all but
  /// name, and is triaged as one.
  bool get needsAttention => lowestRating <= 2;

  bool get hasComment => comment.trim().isNotEmpty;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return clientName.toLowerCase().contains(q) ||
        driverName.toLowerCase().contains(q) ||
        vehicleName.toLowerCase().contains(q) ||
        routeLabel.toLowerCase().contains(q) ||
        bookingNumber.toLowerCase().contains(q) ||
        comment.toLowerCase().contains(q);
  }
}
