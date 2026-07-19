import '../models/package_plan_model.dart';

abstract class PackagesDatasource {
  /// Active packages, ordered by the Dashboard's `display_order`.
  Future<List<PackagePlanModel>> getPackages();
}
