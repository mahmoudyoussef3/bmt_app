enum PackageType {
  oneTime('رحلة واحدة'),
  fiveDays('باقة ٥ أيام'),
  tenDaysMonthly('باقة ١٠ أيام شهريًا'),
  monthly('باقة شهر'),
  threeMonths('باقة ٣ شهور');

  final String labelAr;

  const PackageType(this.labelAr);
}

class PackagePlanEntity {
  final String id;
  final String nameAr;
  final String descriptionAr;
  final PackageType packageType;
  final int durationDays;
  final int rideDays;
  final double price;
  final String currency;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const PackagePlanEntity({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.packageType,
    required this.durationDays,
    required this.rideDays,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  PackagePlanEntity copyWith({
    String? id,
    String? nameAr,
    String? descriptionAr,
    PackageType? packageType,
    int? durationDays,
    int? rideDays,
    double? price,
    String? currency,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return PackagePlanEntity(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      packageType: packageType ?? this.packageType,
      durationDays: durationDays ?? this.durationDays,
      rideDays: rideDays ?? this.rideDays,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RoutePointEntity {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;

  const RoutePointEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
  });
}

class RoutePackagePriceEntity {
  final String id;
  final String routeId;
  final String routeName;
  final String fromPointId;
  final String fromPointName;
  final String toPointId;
  final String toPointName;
  final String packagePlanId;
  final String packageName;
  final double price;
  final String currency;
  final bool isActive;

  const RoutePackagePriceEntity({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.fromPointId,
    required this.fromPointName,
    required this.toPointId,
    required this.toPointName,
    required this.packagePlanId,
    required this.packageName,
    required this.price,
    this.currency = 'ج.م',
    required this.isActive,
  });

  RoutePackagePriceEntity copyWith({
    String? id,
    String? routeId,
    String? routeName,
    String? fromPointId,
    String? fromPointName,
    String? toPointId,
    String? toPointName,
    String? packagePlanId,
    String? packageName,
    double? price,
    String? currency,
    bool? isActive,
  }) {
    return RoutePackagePriceEntity(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      fromPointId: fromPointId ?? this.fromPointId,
      fromPointName: fromPointName ?? this.fromPointName,
      toPointId: toPointId ?? this.toPointId,
      toPointName: toPointName ?? this.toPointName,
      packagePlanId: packagePlanId ?? this.packagePlanId,
      packageName: packageName ?? this.packageName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TripPackagePriceEntity {
  final String id;
  final String tripId;
  final String routeId;
  final String packagePlanId;
  final double price;
  final String currency;
  final bool isActive;

  const TripPackagePriceEntity({
    required this.id,
    required this.tripId,
    required this.routeId,
    required this.packagePlanId,
    required this.price,
    this.currency = 'ج.م',
    required this.isActive,
  });
}

class PackageRouteEntity {
  final String id;
  final String name;
  final List<RoutePointEntity> points;

  const PackageRouteEntity({
    required this.id,
    required this.name,
    required this.points,
  });
}
