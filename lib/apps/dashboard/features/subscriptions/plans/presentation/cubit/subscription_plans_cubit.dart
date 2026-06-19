import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/usecases/subscription_plans_usecases.dart';
import 'subscription_plans_state.dart';

class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  final GetSubscriptionPlansUseCase _getPlans;
  final CreateSubscriptionPlanUseCase _createPlan;
  final UpdateSubscriptionPlanUseCase _updatePlan;
  final SetSubscriptionPlanStatusUseCase _setStatus;
  final DeleteSubscriptionPlanUseCase _deletePlan;

  SubscriptionPlansCubit({
    required GetSubscriptionPlansUseCase getPlans,
    required CreateSubscriptionPlanUseCase createPlan,
    required UpdateSubscriptionPlanUseCase updatePlan,
    required SetSubscriptionPlanStatusUseCase setStatus,
    required DeleteSubscriptionPlanUseCase deletePlan,
  })  : _getPlans = getPlans,
        _createPlan = createPlan,
        _updatePlan = updatePlan,
        _setStatus = setStatus,
        _deletePlan = deletePlan,
        super(const SubscriptionPlansLoading());

  Future<void> load() async {
    emit(const SubscriptionPlansLoading());
    try {
      emit(SubscriptionPlansLoaded(plans: await _getPlans()));
    } catch (error) {
      emit(SubscriptionPlansError(error.toString()));
    }
  }

  Future<void> create(SubscriptionPlan plan) =>
      _mutate(() => _createPlan(plan), 'تم إنشاء الباقة بنجاح');

  Future<void> update(SubscriptionPlan plan) =>
      _mutate(() => _updatePlan(plan), 'تم تحديث الباقة بنجاح');

  Future<void> setStatus(String id, PlanStatus status) =>
      _mutate(() => _setStatus(id, status), 'تم تحديث حالة الباقة');

  Future<void> delete(String id) =>
      _mutate(() => _deletePlan(id), 'تم حذف الباقة');

  Future<void> _mutate(Future<void> Function() action, String message) async {
    final current = state;
    if (current is! SubscriptionPlansLoaded) return;
    emit(current.copyWith(mutating: true, clearMessage: true));
    try {
      await action();
      final plans = await _getPlans();
      emit(SubscriptionPlansLoaded(plans: plans, actionMessage: message));
    } catch (error) {
      emit(current.copyWith(mutating: false, actionMessage: error.toString()));
    }
  }
}
