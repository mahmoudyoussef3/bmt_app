import '../../domain/entities/subscription_request.dart';
import '../models/package_plan_model.dart';

abstract class PackagesDatasource {
  Future<PackageSelectionDataModel> getSelectionData();

  /// Persists a new active subscription and returns its id.
  Future<String> createSubscription(SubscriptionRequest request);
}
