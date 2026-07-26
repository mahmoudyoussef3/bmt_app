import '../entities/package_filter.dart';
import '../entities/package_plan.dart';

class FilterPackagesUseCase {
  const FilterPackagesUseCase();

  /// Narrows the catalogue by duration [filter] and, when set, by selling
  /// office ([officeId]). Both are independent marketplace lenses, so a rider
  /// can ask for "monthly packages from this office" in one view.
  List<PackagePlan> call({
    required List<PackagePlan> packages,
    required PackageFilter filter,
    String? officeId,
  }) {
    return packages
        .where((package) {
          final matchesDuration = filter.matches(package.durationDays);
          final matchesOffice =
              officeId == null ||
              officeId.isEmpty ||
              package.officeId == officeId;
          return matchesDuration && matchesOffice;
        })
        .toList(growable: false);
  }
}
