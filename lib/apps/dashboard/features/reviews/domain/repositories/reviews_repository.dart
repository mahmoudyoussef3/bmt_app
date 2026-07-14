import '../entities/trip_review_entry.dart';

abstract class ReviewsRepository {
  /// Every passenger review, newest first.
  Future<List<TripReviewEntry>> getReviews();

  /// Live feed — a review that lands while operations is looking at the board
  /// should appear without a manual refresh.
  Stream<List<TripReviewEntry>> watchReviews();
}
