import '../repositories/reports_repository.dart';

class GetAvailableRoutesUseCase {
  final ReportsRepository _repository;

  const GetAvailableRoutesUseCase(this._repository);

  Future<List<String>> call() => _repository.getAvailableRoutes();
}
