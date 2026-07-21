import '../entities/office_summary.dart';
import '../repositories/offices_repository.dart';

class GetOfficesUseCase {
  const GetOfficesUseCase(this._repository);

  final OfficesRepository _repository;

  Future<List<OfficeSummary>> call() => _repository.getOffices();
}
