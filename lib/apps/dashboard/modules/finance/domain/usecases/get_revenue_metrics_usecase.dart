import '../entities/finance_entities.dart';
import '../repositories/finance_repository.dart';

class GetRevenueMetricsUseCase {
  final FinanceRepository _repository;

  const GetRevenueMetricsUseCase(this._repository);

  Future<RevenueMetrics> call() => _repository.getRevenueMetrics();
}
