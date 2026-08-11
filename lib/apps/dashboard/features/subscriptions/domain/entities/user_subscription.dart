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

  /// The package (`packages` catalogue) the subscriber bought.
  ///
  /// Empty for subscriptions mirrored from a booking: the booking flow sells
  /// from `transport_packages`, a different catalogue, so only the title
  /// survives into [packageName]. See the two-worlds note in
  /// `20260706130000_subscription_from_approved_booking.sql`.
  final String packageId;
  final String packageName;

  /// The office route (`operation_routes`) this subscription is sold on.
  ///
  /// This is what makes the trip filter real: a subscriber attached to a route
  /// is eligible for every trip that runs on it inside their plan window.
  /// Empty for subscriptions that predate the link or were created without a
  /// route.
  final String routeId;

  /// The route/line the subscriber actually rides (e.g. "بنها - مدينة نصر").
  /// Taken from the joined `operation_routes` row when [routeId] is set, and
  /// from the historical `route_name` text otherwise. Kept distinct from the
  /// package title in [packageName], so the dashboard can show each subscriber
  /// both the package they bought and the line they ride.
  final String routeLabel;

  /// The trip whose approved booking created this subscription, when it came
  /// from the booking flow. Empty for subscriptions the office created by hand.
  final String originTripId;

  /// The approved `operation_bookings` row this subscription was mirrored from.
  final String originBookingId;

  final SubscriptionType type;

  final double price;
  final String currency;

  final int totalRides;
  final int usedRides;
  final int remainingRides;

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

  /// Active but inside its last week — the set an office renews before it
  /// lapses, and the reason the list carries a dedicated tab for it.
  bool get isExpiringSoon =>
      status == SubscriptionStatus.active &&
      remainingDays > 0 &&
      remainingDays <= 7;

  /// Money still owed on this subscription. `remaining_amount` is the column
  /// the database maintains; the price/paid difference is only a fallback for
  /// old rows written before it was populated.
  double get outstandingAmount {
    if (remainingAmount > 0) return remainingAmount;
    final difference = price - paidAmount;
    return difference > 0 ? difference : 0;
  }

  bool get hasOutstandingBalance => outstandingAmount > 0.009;

  /// Whether this subscription can still be used for a ride today: the ride
  /// RPC applies exactly these conditions, so the UI must not offer the action
  /// when they do not hold.
  bool get canConsumeRide {
    if (status != SubscriptionStatus.active) return false;
    if (totalRides > 0 && remainingRides <= 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !start.isAfter(today) && !end.isBefore(today);
  }

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.packageId,
    required this.packageName,
    this.routeId = '',
    this.routeLabel = '',
    this.originTripId = '',
    this.originBookingId = '',
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
    String? packageId,
    String? packageName,
    String? routeId,
    String? routeLabel,
    String? originTripId,
    String? originBookingId,
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
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      routeId: routeId ?? this.routeId,
      routeLabel: routeLabel ?? this.routeLabel,
      originTripId: originTripId ?? this.originTripId,
      originBookingId: originBookingId ?? this.originBookingId,
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

/// A route the subscriber can be attached to, sourced from `operation_routes`
/// — the office-scoped route table the rest of the dashboard runs on.
///
/// It used to come from the legacy global `routes` table, which carries no
/// `office_id`, so the picker offered every office's routes and the chosen id
/// could not be stored against the subscription at all.
class SubscriptionRouteOption {
  final String id;
  final String label;
  final String status;

  const SubscriptionRouteOption({
    required this.id,
    required this.label,
    this.status = 'active',
  });
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
