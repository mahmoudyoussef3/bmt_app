import '../entities/package_plan.dart';
import '../entities/subscription_request.dart';

abstract class PackagesRepository {
  Future<PackageSelectionData> getSelectionData();

  Future<String> createSubscription(SubscriptionRequest request);
}
