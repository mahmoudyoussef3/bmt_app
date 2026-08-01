import '../../domain/entities/user_subscription.dart';

/// The queues an office works its subscribers through, in the order the work
/// actually arrives: money to collect first, then renewals about to lapse.
enum SubscriptionQueueTab {
  pendingPayment('بانتظار الدفع'),
  active('نشط'),
  expiringSoon('ينتهي قريبًا'),
  expired('منتهي'),
  cancelled('ملغي'),
  all('الكل');

  final String label;

  const SubscriptionQueueTab(this.label);

  bool matches(UserSubscription subscription) => switch (this) {
    SubscriptionQueueTab.all => true,
    SubscriptionQueueTab.expiringSoon => subscription.isExpiringSoon,
    SubscriptionQueueTab.pendingPayment =>
      subscription.status == SubscriptionStatus.pendingPayment,
    SubscriptionQueueTab.active =>
      subscription.status == SubscriptionStatus.active,
    SubscriptionQueueTab.expired =>
      subscription.status == SubscriptionStatus.expired,
    SubscriptionQueueTab.cancelled =>
      subscription.status == SubscriptionStatus.cancelled,
  };

  /// Queues that represent outstanding work, so the tab strip can keep them
  /// visually distinct even when another tab is selected.
  bool get isWorkQueue =>
      this == SubscriptionQueueTab.pendingPayment ||
      this == SubscriptionQueueTab.expiringSoon;
}
