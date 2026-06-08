import '../../domain/entities/package_pricing.dart';

class PackagePlanModel extends PackagePlanEntity {
  const PackagePlanModel({
    required super.id,
    required super.nameAr,
    required super.descriptionAr,
    required super.packageType,
    required super.durationDays,
    required super.rideDays,
    required super.price,
    required super.currency,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PackagePlanModel.fromEntity(PackagePlanEntity entity) {
    return PackagePlanModel(
      id: entity.id,
      nameAr: entity.nameAr,
      descriptionAr: entity.descriptionAr,
      packageType: entity.packageType,
      durationDays: entity.durationDays,
      rideDays: entity.rideDays,
      price: entity.price,
      currency: entity.currency,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class RoutePackagePriceModel extends RoutePackagePriceEntity {
  const RoutePackagePriceModel({
    required super.id,
    required super.routeId,
    required super.routeName,
    required super.fromPointId,
    required super.fromPointName,
    required super.toPointId,
    required super.toPointName,
    required super.packagePlanId,
    required super.packageName,
    required super.price,
    required super.currency,
    required super.isActive,
  });

  factory RoutePackagePriceModel.fromEntity(RoutePackagePriceEntity entity) {
    return RoutePackagePriceModel(
      id: entity.id,
      routeId: entity.routeId,
      routeName: entity.routeName,
      fromPointId: entity.fromPointId,
      fromPointName: entity.fromPointName,
      toPointId: entity.toPointId,
      toPointName: entity.toPointName,
      packagePlanId: entity.packagePlanId,
      packageName: entity.packageName,
      price: entity.price,
      currency: entity.currency,
      isActive: entity.isActive,
    );
  }
}

class TripPackagePriceModel extends TripPackagePriceEntity {
  const TripPackagePriceModel({
    required super.id,
    required super.tripId,
    required super.routeId,
    required super.packagePlanId,
    required super.price,
    required super.currency,
    required super.isActive,
  });

  factory TripPackagePriceModel.fromEntity(TripPackagePriceEntity entity) {
    return TripPackagePriceModel(
      id: entity.id,
      tripId: entity.tripId,
      routeId: entity.routeId,
      packagePlanId: entity.packagePlanId,
      price: entity.price,
      currency: entity.currency,
      isActive: entity.isActive,
    );
  }
}
