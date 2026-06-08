import '../entities/package_pricing.dart';

abstract class PackagesRepository {
  Future<List<PackagePlanEntity>> getPackagePlans();
  Future<PackagePlanEntity> createPackagePlan(PackagePlanEntity plan);
  Future<PackagePlanEntity> updatePackagePlan(PackagePlanEntity plan);
  Future<PackagePlanEntity> togglePackagePlanStatus(String planId);
  Future<List<PackageRouteEntity>> getRoutes();
  Future<List<RoutePackagePriceEntity>> getRoutePackagePrices(String routeId);
  Future<RoutePackagePriceEntity> assignPackagePriceToRoutePoints(
    RoutePackagePriceEntity price,
  );
  Future<RoutePackagePriceEntity> updateRoutePackagePrice(
    RoutePackagePriceEntity price,
  );
  Future<List<TripPackagePriceEntity>> getTripPackagePrices(String tripId);
  Future<TripPackagePriceEntity> assignPackagePriceToTrip(
    TripPackagePriceEntity price,
  );
}
