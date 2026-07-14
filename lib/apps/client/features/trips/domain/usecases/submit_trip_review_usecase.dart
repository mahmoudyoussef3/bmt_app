import '../entities/trip.dart';
import '../entities/trip_review.dart';
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

  Future<void> call(TripData trip, TripReview review) {
    if (trip.status != TripStatus.completed) {
      throw Exception('You can only review a trip once it has been completed.');
    }
    if (!review.isValid) {
      throw Exception('Please give the driver, vehicle, and route 1–5 stars.');
    }
    return _repository.submitReview(review);
  }
}
