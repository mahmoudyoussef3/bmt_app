/// A passenger's review of one completed booking.
///
/// The passenger rates four things separately, because "the trip was bad" is
/// not actionable: a late departure (route), a rude captain (driver), and a
/// broken air-conditioner (vehicle) land on three different desks — and the
/// transport office that sold the trip is a marketplace entity in its own right,
/// so it carries its own reputation rather than inheriting an average of the
/// other three.
class TripReview {
  const TripReview({
    required this.bookingId,
    required this.officeRating,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    this.comment = '',
    this.submittedAt,
  });

  final String bookingId;
  final int officeRating;
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
      isValidRating(officeRating) &&
      isValidRating(driverRating) &&
      isValidRating(vehicleRating) &&
      isValidRating(routeRating);

  double get averageRating =>
      (officeRating + driverRating + vehicleRating + routeRating) / 4;

  /// The same review, now recorded. [at] is this device's clock; the server's
  /// own `created_at` replaces it the next time the review is read back.
  TripReview markSubmitted(DateTime at) => TripReview(
    bookingId: bookingId,
    officeRating: officeRating,
    driverRating: driverRating,
    vehicleRating: vehicleRating,
    routeRating: routeRating,
    comment: comment,
    submittedAt: at,
  );

  TripReview copyWith({
    int? officeRating,
    int? driverRating,
    int? vehicleRating,
    int? routeRating,
    String? comment,
  }) {
    return TripReview(
      bookingId: bookingId,
      officeRating: officeRating ?? this.officeRating,
      driverRating: driverRating ?? this.driverRating,
      vehicleRating: vehicleRating ?? this.vehicleRating,
      routeRating: routeRating ?? this.routeRating,
      comment: comment ?? this.comment,
      submittedAt: submittedAt,
    );
  }
}
