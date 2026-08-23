import '../../domain/entities/user_subscription.dart';

/// Orderings the list offers. Each one answers a real question — who is about
/// to lapse, who owes the most, who has rides left to burn.
enum SubscriptionSortField {
  createdAt('الأحدث'),
  endingSoon('الأقرب انتهاءً'),
  outstanding('الأعلى مديونية'),
  ridesLeft('الأكثر رصيدًا'),
  price('الأعلى قيمة'),
  name('الاسم');

  final String label;

  const SubscriptionSortField(this.label);

  /// Ascending comparison; the cubit flips it for descending order.
  int compare(UserSubscription a, UserSubscription b) => switch (this) {
    SubscriptionSortField.createdAt => a.createdAt.compareTo(b.createdAt),
    SubscriptionSortField.endingSoon => a.endDate.compareTo(b.endDate),
    SubscriptionSortField.outstanding => a.outstandingAmount.compareTo(
      b.outstandingAmount,
    ),
    SubscriptionSortField.ridesLeft => a.remainingRides.compareTo(
      b.remainingRides,
    ),
    SubscriptionSortField.price => a.price.compareTo(b.price),
    SubscriptionSortField.name => a.userName.compareTo(b.userName),
  };

  /// The direction that puts the interesting rows first for this field —
  /// newest subscriptions, but the *soonest* expiry.
  bool get defaultAscending => this == SubscriptionSortField.endingSoon;
}
