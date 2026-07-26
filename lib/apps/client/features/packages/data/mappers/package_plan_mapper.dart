import '../../domain/entities/package_plan.dart';
import '../models/package_plan_model.dart';

extension PackagePlanMapper on PackagePlanModel {
  PackagePlan toEntity() => PackagePlan(
    id: id,
    nameAr: nameAr,
    nameEn: nameEn,
    packageType: packageType,
    durationDays: durationDays,
    rideCount: rideCount,
    price: price,
    officeId: officeId,
    officeName: officeName,
    officeLogoUrl: officeLogoUrl,
    officeRating: officeRating,
    officeRatingsCount: officeRatingsCount,
  );
}

extension PackagePlanListMapper on List<PackagePlanModel> {
  List<PackagePlan> toEntities() => map((model) => model.toEntity()).toList();
}
