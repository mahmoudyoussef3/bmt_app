import '../entities/package_plan.dart';

abstract class PackagesRepository {
  /// The active package catalogue, in the order the Dashboard publishes it.
  Future<List<PackagePlan>> getPackages();
}
