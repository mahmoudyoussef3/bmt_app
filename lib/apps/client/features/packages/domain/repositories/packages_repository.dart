import '../entities/my_subscription.dart';
import '../entities/package_plan.dart';

abstract class PackagesRepository {
  /// The active package catalogue, in the order the Dashboard publishes it.
  Future<List<PackagePlan>> getPackages();

  /// The subscription the signed-in rider currently holds, or `null` when
  /// they have none.
  Future<MySubscription?> getMySubscription();
}
