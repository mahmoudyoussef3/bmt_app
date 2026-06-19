import '../../domain/entities/subscription_plan.dart';

sealed class SubscriptionPlansState {
  const SubscriptionPlansState();
}

class SubscriptionPlansLoading extends SubscriptionPlansState {
  const SubscriptionPlansLoading();
}

class SubscriptionPlansError extends SubscriptionPlansState {
  final String message;
  const SubscriptionPlansError(this.message);
}

class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlan> plans;
  final bool mutating;
  final String? actionMessage;

  const SubscriptionPlansLoaded({
    required this.plans,
    this.mutating = false,
    this.actionMessage,
  });

  double get monthlyRecurringRevenue =>
      plans.where((p) => p.status == PlanStatus.active).fold(0, (s, p) => s + p.price);

  SubscriptionPlansLoaded copyWith({
    List<SubscriptionPlan>? plans,
    bool? mutating,
    String? actionMessage,
    bool clearMessage = false,
  }) {
    return SubscriptionPlansLoaded(
      plans: plans ?? this.plans,
      mutating: mutating ?? this.mutating,
      actionMessage: clearMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }
}
