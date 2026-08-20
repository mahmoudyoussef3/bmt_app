import '../entities/my_subscription.dart';
import '../entities/package_plan.dart';

abstract class PackagesRepository {
  /// The active catalog packages of one office, for its marketplace profile.
  /// Only packages whose selling office is listed are returned — a package
  /// from a paused/unlisted office carries no provider identity and is not
  /// for sale.
  ///
  /// There is deliberately no catalogue-wide read any more: the booking
  /// wizard used one, which offered every office's packages on every trip.
  Future<List<PackagePlan>> getOfficePackages(String officeId);

  /// The fare menu of one trip: exactly the packages the office put on it,
  /// plus that office's walk-up single-ride package. Same listed-office
  /// guarantee as [getOfficePackages].
  Future<List<PackagePlan>> getTripPackages({
    required String officeId,
    required Set<String> packageIds,
  });

  /// The subscription the signed-in rider currently holds, or `null` when
  /// they have none.
  Future<MySubscription?> getMySubscription();
}
