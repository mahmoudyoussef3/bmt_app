import '../entities/finance_analytics.dart';
import '../repositories/finance_repository.dart';

/// Downloads the period's financial statement. Returns the saved file name.
class ExportFinanceStatementUseCase {
  final FinanceRepository _repository;

  const ExportFinanceStatementUseCase(this._repository);

  Future<String> call(FinanceStatement statement, String format) =>
      _repository.exportStatement(statement, format);
}
