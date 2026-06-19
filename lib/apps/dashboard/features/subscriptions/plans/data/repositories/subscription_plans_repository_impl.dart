import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscription_plans_repository.dart';
import '../datasources/subscription_plans_datasource.dart';

class SubscriptionPlansRepositoryImpl implements SubscriptionPlansRepository {
  final SubscriptionPlansDatasource _datasource;

  const SubscriptionPlansRepositoryImpl(this._datasource);

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      return await _datasource.getPlans();
    } catch (_) {
      throw Exception('تعذر تحميل الباقات');
    }
  }

  @override
  Future<void> createPlan(SubscriptionPlan plan) async {
    try {
      await _datasource.createPlan(plan);
    } catch (_) {
      throw Exception('تعذر إنشاء الباقة. تأكد من اكتمال البيانات');
    }
  }

  @override
  Future<void> updatePlan(SubscriptionPlan plan) async {
    try {
      await _datasource.updatePlan(plan);
    } catch (_) {
      throw Exception('تعذر تحديث الباقة');
    }
  }

  @override
  Future<void> setPlanStatus(String id, PlanStatus status) async {
    try {
      await _datasource.setPlanStatus(id, status);
    } catch (_) {
      throw Exception('تعذر تغيير حالة الباقة');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _datasource.deletePlan(id);
    } catch (_) {
      throw Exception('تعذر حذف الباقة');
    }
  }
}
