import '../repositories/reports_repository.dart';

class GetAvailablePackagesUseCase {
  final ReportsRepository _repository;

  const GetAvailablePackagesUseCase(this._repository);

  Future<List<String>> call() => _repository.getAvailablePackages();
}
