import '../models/package_plan_model.dart';

abstract class PackagesDatasource {
  /// Active packages, ordered by the Dashboard's `display_order`. Pass
  /// [officeId] to narrow the read to one office (the office profile does this);
  /// omit it for the full marketplace catalogue.
  Future<List<PackagePlanModel>> getPackages({String? officeId});

  /// The `subscriptions` row the signed-in rider currently owns, or `null`
  /// when they hold none.
  Future<Map<String, dynamic>?> getMySubscription();
}
