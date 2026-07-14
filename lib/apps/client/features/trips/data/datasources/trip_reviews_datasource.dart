import '../../domain/entities/trip_review.dart';
import '../models/trip_review_model.dart';

abstract class TripReviewsDatasource {
  Future<TripReviewModel?> getReviewForBooking(String bookingId);
  Future<void> submitReview(TripReview review);
}
