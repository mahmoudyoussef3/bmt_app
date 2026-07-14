/// A passenger's review of one completed booking.
///
/// The passenger rates three things separately, because "the trip was bad" is
/// not actionable: a late departure (route), a rude captain (driver), and a
/// broken air-conditioner (vehicle) land on three different desks.
class TripReview {
  const TripReview({
    required this.bookingId,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    this.comment = '',
    this.submittedAt,
  });

  final String bookingId;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final String comment;

  /// Null until the review has been stored — a draft the passenger is still
  /// filling in has never been submitted.
  final DateTime? submittedAt;

  static const int minRating = 1;
  static const int maxRating = 5;

  static bool isValidRating(int value) =>
      value >= minRating && value <= maxRating;

  bool get isValid =>
      bookingId.trim().isNotEmpty &&
      isValidRating(driverRating) &&
      isValidRating(vehicleRating) &&
      isValidRating(routeRating);

  double get averageRating =>
      (driverRating + vehicleRating + routeRating) / 3;

  TripReview copyWith({
    int? driverRating,
    int? vehicleRating,
    int? routeRating,
    String? comment,
  }) {
    return TripReview(
      bookingId: bookingId,
      driverRating: driverRating ?? this.driverRating,
      vehicleRating: vehicleRating ?? this.vehicleRating,
      routeRating: routeRating ?? this.routeRating,
      comment: comment ?? this.comment,
      submittedAt: submittedAt,
    );
  }
}
