import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class ReviewReceiptUseCase {
  final FinanceRepository _repository;

  const ReviewReceiptUseCase(this._repository);

  Future<void> call(String id, ReceiptReviewStatus action, {String? notes}) =>
      _repository.reviewReceipt(id, action, notes: notes);
}
