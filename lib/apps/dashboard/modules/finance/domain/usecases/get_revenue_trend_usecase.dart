import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetRevenueTrendUseCase {
  final FinanceRepository _repository;

  const GetRevenueTrendUseCase(this._repository);

  Future<List<RevenueTrendPoint>> call() => _repository.getRevenueTrend();
}
