import '../entities/reviewable_trip.dart';
import '../entities/trip_review.dart';
import '../entities/trip_review_failure.dart';
import '../repositories/trip_reviews_repository.dart';

/// Records a passenger's review of a trip they actually took.
///
/// The same two rules live in `submit_trip_review` on the server — the server
/// is the one that counts. Checking here too means the passenger is told what
/// is wrong immediately, instead of after a round trip that ends in a raw
/// Postgres error.
class SubmitTripReviewUseCase {
  const SubmitTripReviewUseCase(this._repository);

  final TripReviewsRepository _repository;

  Future<void> call(ReviewableTrip trip, TripReview review) {
    if (!trip.isCompleted) {
      throw const TripReviewException(TripReviewFailure.tripNotCompleted);
    }
    if (!review.isValid) {
      throw const TripReviewException(TripReviewFailure.invalidRating);
    }
    return _repository.submitReview(review);
  }
}
