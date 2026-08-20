import '../models/package_plan_model.dart';

abstract class PackagesDatasource {
  /// Active packages from the offices' catalogs, ordered by the Dashboard's
  /// `display_order`. Pass [officeId] to narrow the read to one office (the
  /// office profile does this); omit it for the full marketplace catalogue.
  ///
  /// Never returns a package created for a single trip — those exist only
  /// inside that trip's booking flow, and are read by [getTripPackages].
  Future<List<PackagePlanModel>> getPackages({String? officeId});

  /// The fare menu of one trip: the packages the office put on that trip
  /// ([packageIds], taken from its `trip_package_prices` rows), plus the
  /// office's walk-up single-ride package so a rider can always buy one ride.
  ///
  /// This is what the booking wizard reads. It replaced a platform-wide
  /// catalogue read that offered every office's packages on every trip, none
  /// of which that trip could price.
  Future<List<PackagePlanModel>> getTripPackages({
    required String officeId,
    required Set<String> packageIds,
  });

  /// The `subscriptions` row the signed-in rider currently owns, or `null`
  /// when they hold none.
  Future<Map<String, dynamic>?> getMySubscription();
}
