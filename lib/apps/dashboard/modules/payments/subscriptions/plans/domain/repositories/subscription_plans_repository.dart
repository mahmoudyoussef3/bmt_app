import '../entities/subscription_plan.dart';

abstract class SubscriptionPlansRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<void> createPlan(SubscriptionPlan plan);
  Future<void> updatePlan(SubscriptionPlan plan);
  Future<void> setPlanStatus(String id, PlanStatus status);
  Future<void> deletePlan(String id);
}
