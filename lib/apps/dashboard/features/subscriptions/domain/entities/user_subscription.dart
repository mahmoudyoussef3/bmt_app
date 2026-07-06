enum SubscriptionType {
  oneTime('رحلة واحدة'),
  fiveDays('٥ أيام'),
  tenDaysMonthly('١٠ أيام شهريًا'),
  monthly('شهر'),
  threeMonths('٣ شهور');

  final String label;

  const SubscriptionType(this.label);
}

enum SubscriptionStatus {
  active('نشط'),
  expired('منتهي'),
  cancelled('ملغي'),
  pendingPayment('بانتظار الدفع');

  final String label;

  const SubscriptionStatus(this.label);
}

class UserSubscription {
  final String id;

  final String userId;
  final String userName;
  final String userPhone;

  final String tripId;
  final String routeId;
  final String routeName;

  /// The route/line the subscriber actually rides (e.g. "بنها - مدينة نصر").
  /// Sourced from the `route_name` column and kept distinct from the package
  /// title held in [routeName], so the dashboard can show each subscriber the
  /// exact route they signed up for.
  final String routeLabel;

  final String fromPointId;
  final String fromPointName;
  final String toPointId;
  final String toPointName;

  final SubscriptionType type;

  final double price;
  final String currency;

  final int totalRides;
  final int usedRides;
  final int remainingRides;

  // Real financial fields from the `subscriptions` table.
  final double paidAmount;
  final double remainingAmount;
  final int renewalsCount;

  final DateTime startDate;
  final DateTime endDate;

  final SubscriptionStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Days left until [endDate] (never negative). Real, derived value used in
  /// place of a ride count, which the backend does not track.
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.tripId,
    required this.routeId,
    required this.routeName,
    this.routeLabel = '',
    required this.fromPointId,
    required this.fromPointName,
    required this.toPointId,
    required this.toPointName,
    required this.type,
    required this.price,
    required this.currency,
    required this.totalRides,
    required this.usedRides,
    required this.remainingRides,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.renewalsCount = 0,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? tripId,
    String? routeId,
    String? routeName,
    String? routeLabel,
    String? fromPointId,
    String? fromPointName,
    String? toPointId,
    String? toPointName,
    SubscriptionType? type,
    double? price,
    String? currency,
    int? totalRides,
    int? usedRides,
    int? remainingRides,
    double? paidAmount,
    double? remainingAmount,
    int? renewalsCount,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      tripId: tripId ?? this.tripId,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      routeLabel: routeLabel ?? this.routeLabel,
      fromPointId: fromPointId ?? this.fromPointId,
      fromPointName: fromPointName ?? this.fromPointName,
      toPointId: toPointId ?? this.toPointId,
      toPointName: toPointName ?? this.toPointName,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      totalRides: totalRides ?? this.totalRides,
      usedRides: usedRides ?? this.usedRides,
      remainingRides: remainingRides ?? this.remainingRides,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      renewalsCount: renewalsCount ?? this.renewalsCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubscriptionUserOption {
  final String id;
  final String name;
  final String phone;

  const SubscriptionUserOption({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// A real subscription plan, sourced from the `packages` table.
class SubscriptionPlanOption {
  final String id;
  final String name;
  final double price;
  final String currency;
  final int days;
  final int tripsCount;

  const SubscriptionPlanOption({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.days,
    required this.tripsCount,
  });
}

/// A route the subscriber can be attached to, sourced from the `routes` table
/// (rendered as "pickup - destination").
class SubscriptionRouteOption {
  final String id;
  final String label;

  const SubscriptionRouteOption({required this.id, required this.label});
}

class SubscriptionCreationOptions {
  final List<SubscriptionUserOption> users;
  final List<SubscriptionPlanOption> plans;
  final List<SubscriptionRouteOption> routes;

  const SubscriptionCreationOptions({
    required this.users,
    required this.plans,
    this.routes = const [],
  });
}
