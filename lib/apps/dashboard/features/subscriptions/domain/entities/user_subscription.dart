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

  final DateTime startDate;
  final DateTime endDate;

  final SubscriptionStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.tripId,
    required this.routeId,
    required this.routeName,
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

class SubscriptionTripOption {
  final String id;
  final String routeId;
  final String routeName;
  final List<SubscriptionPointOption> points;
  final List<SubscriptionPricingOption> pricing;

  const SubscriptionTripOption({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.points,
    required this.pricing,
  });
}

class SubscriptionPointOption {
  final String id;
  final String name;
  final int order;

  const SubscriptionPointOption({
    required this.id,
    required this.name,
    required this.order,
  });
}

class SubscriptionPricingOption {
  final String fromPointId;
  final String toPointId;
  final SubscriptionType type;
  final double price;
  final String currency;

  const SubscriptionPricingOption({
    required this.fromPointId,
    required this.toPointId,
    required this.type,
    required this.price,
    required this.currency,
  });
}

class SubscriptionCreationOptions {
  final List<SubscriptionUserOption> users;
  final List<SubscriptionTripOption> trips;

  const SubscriptionCreationOptions({required this.users, required this.trips});
}
