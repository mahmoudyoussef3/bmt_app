import '../repositories/reports_repository.dart';

class GetAvailableVehiclesUseCase {
  final ReportsRepository _repository;

  const GetAvailableVehiclesUseCase(this._repository);

  Future<List<String>> call() => _repository.getAvailableVehicles();
}
