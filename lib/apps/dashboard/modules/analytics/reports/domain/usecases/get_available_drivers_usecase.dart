import '../repositories/reports_repository.dart';

class GetAvailableDriversUseCase {
  final ReportsRepository _repository;

  const GetAvailableDriversUseCase(this._repository);

  Future<List<String>> call() => _repository.getAvailableDrivers();
}
