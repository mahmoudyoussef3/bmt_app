import '../entities/office_route.dart';
import '../repositories/offices_repository.dart';

class GetOfficeRoutesUseCase {
  const GetOfficeRoutesUseCase(this._repository);

  final OfficesRepository _repository;

  Future<List<OfficeRoute>> call(String officeId) =>
      _repository.getOfficeRoutes(officeId);
}
