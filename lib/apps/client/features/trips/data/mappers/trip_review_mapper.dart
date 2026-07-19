import '../../domain/entities/trip_review.dart';
import '../models/trip_review_model.dart';

/// Maps a stored `trip_reviews` row into the domain [TripReview] the sheet
/// shows back to the passenger.
extension TripReviewMapper on TripReviewModel {
  TripReview toEntity() => TripReview(
    bookingId: bookingId,
    driverRating: driverRating,
    vehicleRating: vehicleRating,
    routeRating: routeRating,
    comment: comment,
    submittedAt: submittedAt,
  );
}
