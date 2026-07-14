import '../../domain/entities/trip_review_entry.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_datasource.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._datasource);

  final ReviewsDatasource _datasource;

  @override
  Future<List<TripReviewEntry>> getReviews() => _datasource.getReviews();

  @override
  Stream<List<TripReviewEntry>> watchReviews() => _datasource.watchReviews();
}
