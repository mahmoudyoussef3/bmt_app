import '../entities/package_plan.dart';
import '../repositories/packages_repository.dart';

class GetPackagesUseCase {
  const GetPackagesUseCase(this._repository);

  final PackagesRepository _repository;

  Future<List<PackagePlan>> call() => _repository.getPackages();
}
