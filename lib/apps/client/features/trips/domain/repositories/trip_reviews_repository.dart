import '../entities/trip_review.dart';

abstract class TripReviewsRepository {
  /// The passenger's own review of this booking, or null if they have not
  /// reviewed it yet. A passenger can never read anyone else's review.
  Future<TripReview?> getReviewForBooking(String bookingId);

  /// Records the review. Submitting twice for the same booking amends the
  /// first one rather than creating a second.
  Future<void> submitReview(TripReview review);
}
