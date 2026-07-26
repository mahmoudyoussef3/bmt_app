import '../entities/my_subscription.dart';
import '../entities/package_plan.dart';

abstract class PackagesRepository {
  /// The active marketplace catalogue, in the order the Dashboard publishes it.
  /// Only packages whose selling office is listed are returned — a package from
  /// a paused/unlisted office carries no provider identity and is not for sale.
  Future<List<PackagePlan>> getPackages();

  /// The active packages of one office, for its marketplace profile. Same
  /// listed-office guarantee as [getPackages].
  Future<List<PackagePlan>> getOfficePackages(String officeId);

  /// The subscription the signed-in rider currently holds, or `null` when
  /// they have none.
  Future<MySubscription?> getMySubscription();
}
