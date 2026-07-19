import '../../domain/entities/trip_review.dart';
import '../../domain/repositories/trip_reviews_repository.dart';
import '../datasources/trip_reviews_datasource.dart';
import '../mappers/trip_review_mapper.dart';

class TripReviewsRepositoryImpl implements TripReviewsRepository {
  const TripReviewsRepositoryImpl(this._datasource);

  final TripReviewsDatasource _datasource;

  @override
  Future<TripReview?> getReviewForBooking(String bookingId) async {
    final model = await _datasource.getReviewForBooking(bookingId);
    return model?.toEntity();
  }

  @override
  Future<void> submitReview(TripReview review) {
    return _datasource.submitReview(review);
  }
}
