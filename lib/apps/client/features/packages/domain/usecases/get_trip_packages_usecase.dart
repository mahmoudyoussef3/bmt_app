import '../entities/package_plan.dart';
import '../repositories/packages_repository.dart';

/// The fare menu of one trip: the packages its office chose to sell on it,
/// plus that office's walk-up single-ride package.
///
/// The booking wizard used to read the whole marketplace catalogue here, which
/// offered every office's packages on every trip — none of which the trip
/// could price. A trip now carries its own menu (`trip_package_prices`, and
/// packages created for that trip alone), so the rider is shown exactly what
/// this departure sells.
class GetTripPackagesUseCase {
  const GetTripPackagesUseCase(this._repository);

  final PackagesRepository _repository;

  Future<List<PackagePlan>> call({
    required String officeId,
    required Set<String> packageIds,
  }) => _repository.getTripPackages(officeId: officeId, packageIds: packageIds);
}
