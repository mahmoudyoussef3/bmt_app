import '../entities/trip_review.dart';
import '../repositories/trip_reviews_repository.dart';

/// Loads the passenger's existing review of a booking, so the app can show it
/// back to them instead of offering a blank form they have already filled in.
class GetTripReviewUseCase {
  const GetTripReviewUseCase(this._repository);

  final TripReviewsRepository _repository;

  Future<TripReview?> call(String bookingId) {
    if (bookingId.trim().isEmpty) return Future.value(null);
    return _repository.getReviewForBooking(bookingId);
  }
}
