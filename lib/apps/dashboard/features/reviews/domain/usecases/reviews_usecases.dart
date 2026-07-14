import '../entities/trip_review_entry.dart';
import '../repositories/reviews_repository.dart';

class GetReviewsUseCase {
  const GetReviewsUseCase(this._repository);

  final ReviewsRepository _repository;

  Future<List<TripReviewEntry>> call() => _repository.getReviews();
}

class WatchReviewsUseCase {
  const WatchReviewsUseCase(this._repository);

  final ReviewsRepository _repository;

  Stream<List<TripReviewEntry>> call() => _repository.watchReviews();
}
