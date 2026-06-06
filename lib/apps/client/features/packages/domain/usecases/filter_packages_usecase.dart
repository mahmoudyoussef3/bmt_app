import '../entities/package_plan.dart';

class FilterPackagesUseCase {
  const FilterPackagesUseCase();

  List<PackagePlan> call({
    required List<PackagePlan> packages,
    required String filter,
  }) {
    return packages.where((package) {
      if (filter == 'All') return true;
      if (filter == 'Weekly' && package.days <= 14) return true;
      if (filter == 'Monthly' && package.days == 30) return true;
      if (filter == 'Quarterly' && package.days == 90) return true;
      return false;
    }).toList();
  }
}
