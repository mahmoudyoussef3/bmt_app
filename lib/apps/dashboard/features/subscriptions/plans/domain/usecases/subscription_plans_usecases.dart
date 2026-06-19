import '../entities/subscription_plan.dart';
import '../repositories/subscription_plans_repository.dart';

class GetSubscriptionPlansUseCase {
  final SubscriptionPlansRepository _repo;
  const GetSubscriptionPlansUseCase(this._repo);
  Future<List<SubscriptionPlan>> call() => _repo.getPlans();
}

class CreateSubscriptionPlanUseCase {
  final SubscriptionPlansRepository _repo;
  const CreateSubscriptionPlanUseCase(this._repo);
  Future<void> call(SubscriptionPlan plan) => _repo.createPlan(plan);
}

class UpdateSubscriptionPlanUseCase {
  final SubscriptionPlansRepository _repo;
  const UpdateSubscriptionPlanUseCase(this._repo);
  Future<void> call(SubscriptionPlan plan) => _repo.updatePlan(plan);
}

class SetSubscriptionPlanStatusUseCase {
  final SubscriptionPlansRepository _repo;
  const SetSubscriptionPlanStatusUseCase(this._repo);
  Future<void> call(String id, PlanStatus status) =>
      _repo.setPlanStatus(id, status);
}

class DeleteSubscriptionPlanUseCase {
  final SubscriptionPlansRepository _repo;
  const DeleteSubscriptionPlanUseCase(this._repo);
  Future<void> call(String id) => _repo.deletePlan(id);
}
