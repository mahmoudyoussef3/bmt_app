/// Wire shape of a row in the `trip_reviews` table.
class TripReviewModel {
  const TripReviewModel({
    required this.bookingId,
    required this.officeRating,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.comment,
    this.submittedAt,
  });

  final String bookingId;
  final int officeRating;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final String comment;
  final DateTime? submittedAt;

  factory TripReviewModel.fromJson(Map<String, dynamic> json) {
    return TripReviewModel(
      bookingId: json['booking_id']?.toString() ?? '',
      officeRating: (json['office_rating'] as num?)?.toInt() ?? 0,
      driverRating: (json['driver_rating'] as num?)?.toInt() ?? 0,
      vehicleRating: (json['vehicle_rating'] as num?)?.toInt() ?? 0,
      routeRating: (json['route_rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      submittedAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
