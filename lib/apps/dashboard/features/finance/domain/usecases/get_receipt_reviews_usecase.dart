import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetReceiptReviewsUseCase {
  final FinanceRepository _repository;

  const GetReceiptReviewsUseCase(this._repository);

  Future<List<ReceiptReview>> call() => _repository.getReceiptReviews();
}
