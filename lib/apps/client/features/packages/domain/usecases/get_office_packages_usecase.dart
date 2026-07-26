import '../entities/package_plan.dart';
import '../repositories/packages_repository.dart';

/// The active packages one office sells, for its marketplace profile. Lets the
/// office profile close the discovery loop (package → office → its packages)
/// without the offices feature owning a second packages datasource.
class GetOfficePackagesUseCase {
  const GetOfficePackagesUseCase(this._repository);

  final PackagesRepository _repository;

  Future<List<PackagePlan>> call(String officeId) =>
      _repository.getOfficePackages(officeId);
}
