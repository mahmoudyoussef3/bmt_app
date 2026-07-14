import '../../domain/entities/trip_review_entry.dart';

abstract class ReviewsDatasource {
  Future<List<TripReviewEntry>> getReviews();
  Stream<List<TripReviewEntry>> watchReviews();
}
