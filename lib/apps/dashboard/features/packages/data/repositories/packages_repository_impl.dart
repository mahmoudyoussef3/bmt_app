import '../../domain/entities/package_pricing.dart';
import '../../domain/repositories/packages_repository.dart';
import '../datasources/mock_packages_datasource.dart';

class PackagesRepositoryImpl implements PackagesRepository {
  final PackagesDatasource _datasource;

  const PackagesRepositoryImpl(this._datasource);

  @override
  Future<RoutePackagePriceEntity> assignPackagePriceToRoutePoints(
    RoutePackagePriceEntity price,
  ) async {
    try {
      return await _datasource.assignPackagePriceToRoutePoints(price);
    } catch (_) {
      throw Exception(
        'تعذر حفظ السعر. تأكد من ترتيب النقاط وأن السعر أكبر من صفر.',
      );
    }
  }

  @override
  Future<TripPackagePriceEntity> assignPackagePriceToTrip(
    TripPackagePriceEntity price,
  ) async {
    try {
      return await _datasource.assignPackagePriceToTrip(price);
    } catch (_) {
      throw Exception('تعذر حفظ سعر الرحلة');
    }
  }

  @override
  Future<PackagePlanEntity> createPackagePlan(PackagePlanEntity plan) async {
    try {
      return await _datasource.createPackagePlan(plan);
    } catch (_) {
      throw Exception('تعذر إنشاء الباقة');
    }
  }

  @override
  Future<List<PackagePlanEntity>> getPackagePlans() async {
    try {
      return await _datasource.fetchPackagePlans();
    } catch (_) {
      throw Exception('تعذر تحميل الباقات');
    }
  }

  @override
  Future<List<PackageRouteEntity>> getRoutes() async {
    try {
      return await _datasource.fetchRoutes();
    } catch (_) {
      throw Exception('تعذر تحميل المسارات');
    }
  }

  @override
  Future<List<RoutePackagePriceEntity>> getRoutePackagePrices(
    String routeId,
  ) async {
    try {
      return await _datasource.fetchRoutePackagePrices(routeId);
    } catch (_) {
      throw Exception('تعذر تحميل أسعار المسار');
    }
  }

  @override
  Future<List<TripPackagePriceEntity>> getTripPackagePrices(
    String tripId,
  ) async {
    try {
      return await _datasource.fetchTripPackagePrices(tripId);
    } catch (_) {
      throw Exception('تعذر تحميل أسعار الرحلة');
    }
  }

  @override
  Future<PackagePlanEntity> togglePackagePlanStatus(String planId) async {
    try {
      return await _datasource.togglePackagePlanStatus(planId);
    } catch (_) {
      throw Exception('تعذر تغيير حالة الباقة');
    }
  }

  @override
  Future<PackagePlanEntity> updatePackagePlan(PackagePlanEntity plan) async {
    try {
      return await _datasource.updatePackagePlan(plan);
    } catch (_) {
      throw Exception('تعذر تعديل الباقة');
    }
  }

  @override
  Future<RoutePackagePriceEntity> updateRoutePackagePrice(
    RoutePackagePriceEntity price,
  ) async {
    try {
      return await _datasource.updateRoutePackagePrice(price);
    } catch (_) {
      throw Exception('تعذر تعديل سعر المسار');
    }
  }
}
