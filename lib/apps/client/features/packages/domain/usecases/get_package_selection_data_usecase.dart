import '../entities/package_plan.dart';
import '../repositories/packages_repository.dart';

class GetPackageSelectionDataUseCase {
  const GetPackageSelectionDataUseCase(this._repository);

  final PackagesRepository _repository;

  Future<PackageSelectionData> call() {
    return _repository.getSelectionData();
  }
}
