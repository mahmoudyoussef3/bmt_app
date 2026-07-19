import '../entities/package_filter.dart';
import '../entities/package_plan.dart';

class FilterPackagesUseCase {
  const FilterPackagesUseCase();

  List<PackagePlan> call({
    required List<PackagePlan> packages,
    required PackageFilter filter,
  }) {
    if (filter == PackageFilter.all) return packages;
    return packages
        .where((package) => filter.matches(package.durationDays))
        .toList();
  }
}
