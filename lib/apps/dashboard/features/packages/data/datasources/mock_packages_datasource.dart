import '../../domain/entities/package_pricing.dart';
import '../models/package_pricing_models.dart';

abstract class PackagesDatasource {
  Future<List<PackagePlanModel>> fetchPackagePlans();
  Future<PackagePlanModel> createPackagePlan(PackagePlanEntity plan);
  Future<PackagePlanModel> updatePackagePlan(PackagePlanEntity plan);
  Future<PackagePlanModel> togglePackagePlanStatus(String planId);
  Future<List<PackageRouteEntity>> fetchRoutes();
  Future<List<RoutePackagePriceModel>> fetchRoutePackagePrices(String routeId);
  Future<RoutePackagePriceModel> assignPackagePriceToRoutePoints(
    RoutePackagePriceEntity price,
  );
  Future<RoutePackagePriceModel> updateRoutePackagePrice(
    RoutePackagePriceEntity price,
  );
  Future<List<TripPackagePriceModel>> fetchTripPackagePrices(String tripId);
  Future<TripPackagePriceModel> assignPackagePriceToTrip(
    TripPackagePriceEntity price,
  );
}

class MockPackagesDatasource implements PackagesDatasource {
  final List<PackagePlanModel> _plans = List<PackagePlanModel>.from(_seedPlans);
  final List<RoutePackagePriceModel> _routePrices =
      List<RoutePackagePriceModel>.from(_seedRoutePrices);
  final List<TripPackagePriceModel> _tripPrices = [];

  @override
  Future<RoutePackagePriceModel> assignPackagePriceToRoutePoints(
    RoutePackagePriceEntity price,
  ) async {
    _validateRoutePrice(price);
    final model = RoutePackagePriceModel.fromEntity(
      price.copyWith(id: 'route-price-${_routePrices.length + 1}'),
    );
    _routePrices.insert(0, model);
    return model;
  }

  @override
  Future<TripPackagePriceModel> assignPackagePriceToTrip(
    TripPackagePriceEntity price,
  ) async {
    if (price.tripId.isEmpty ||
        price.routeId.isEmpty ||
        price.packagePlanId.isEmpty ||
        price.price <= 0) {
      throw ArgumentError('Invalid trip package price');
    }
    final model = TripPackagePriceModel.fromEntity(price);
    _tripPrices.insert(0, model);
    return model;
  }

  @override
  Future<PackagePlanModel> createPackagePlan(PackagePlanEntity plan) async {
    if (plan.nameAr.trim().isEmpty || plan.price <= 0) {
      throw ArgumentError('Invalid package plan');
    }
    final model = PackagePlanModel.fromEntity(
      plan.copyWith(id: 'plan-${_plans.length + 1}', updatedAt: '٨ يونيو ٢٠٢٦'),
    );
    _plans.insert(0, model);
    return model;
  }

  @override
  Future<List<PackagePlanModel>> fetchPackagePlans() async {
    return List<PackagePlanModel>.unmodifiable(_plans);
  }

  @override
  Future<List<RoutePackagePriceModel>> fetchRoutePackagePrices(
    String routeId,
  ) async {
    return _routePrices.where((price) => price.routeId == routeId).toList();
  }

  @override
  Future<List<PackageRouteEntity>> fetchRoutes() async {
    return const [
      PackageRouteEntity(
        id: 'route-banha-fifth',
        name: 'بنها - التجمع الخامس',
        points: [
          RoutePointEntity(
            id: 'point-banha',
            name: 'بنها',
            latitude: 30.466,
            longitude: 31.184,
            order: 1,
          ),
          RoutePointEntity(
            id: 'point-shubra',
            name: 'شبرا',
            latitude: 30.128,
            longitude: 31.242,
            order: 2,
          ),
          RoutePointEntity(
            id: 'point-ramses',
            name: 'رمسيس',
            latitude: 30.062,
            longitude: 31.247,
            order: 3,
          ),
          RoutePointEntity(
            id: 'point-nasr',
            name: 'مدينة نصر',
            latitude: 30.056,
            longitude: 31.33,
            order: 4,
          ),
          RoutePointEntity(
            id: 'point-fifth',
            name: 'التجمع الخامس',
            latitude: 30.008,
            longitude: 31.428,
            order: 5,
          ),
        ],
      ),
      PackageRouteEntity(
        id: 'route-maadi-capital',
        name: 'المعادي - العاصمة الإدارية',
        points: [
          RoutePointEntity(
            id: 'point-maadi',
            name: 'المعادي',
            latitude: 29.96,
            longitude: 31.25,
            order: 1,
          ),
          RoutePointEntity(
            id: 'point-zahraa',
            name: 'زهراء المعادي',
            latitude: 29.98,
            longitude: 31.31,
            order: 2,
          ),
          RoutePointEntity(
            id: 'point-kattameya',
            name: 'القطامية',
            latitude: 30.02,
            longitude: 31.38,
            order: 3,
          ),
          RoutePointEntity(
            id: 'point-capital',
            name: 'العاصمة الإدارية',
            latitude: 30.01,
            longitude: 31.72,
            order: 4,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<TripPackagePriceModel>> fetchTripPackagePrices(
    String tripId,
  ) async {
    return _tripPrices.where((price) => price.tripId == tripId).toList();
  }

  @override
  Future<PackagePlanModel> togglePackagePlanStatus(String planId) async {
    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) throw ArgumentError('Package plan not found');
    final updated = PackagePlanModel.fromEntity(
      _plans[index].copyWith(
        isActive: !_plans[index].isActive,
        updatedAt: '٨ يونيو ٢٠٢٦',
      ),
    );
    _plans[index] = updated;
    return updated;
  }

  @override
  Future<PackagePlanModel> updatePackagePlan(PackagePlanEntity plan) async {
    final index = _plans.indexWhere((item) => item.id == plan.id);
    if (index == -1) throw ArgumentError('Package plan not found');
    if (plan.nameAr.trim().isEmpty || plan.price <= 0) {
      throw ArgumentError('Invalid package plan');
    }
    final model = PackagePlanModel.fromEntity(
      plan.copyWith(updatedAt: '٨ يونيو ٢٠٢٦'),
    );
    _plans[index] = model;
    return model;
  }

  @override
  Future<RoutePackagePriceModel> updateRoutePackagePrice(
    RoutePackagePriceEntity price,
  ) async {
    _validateRoutePrice(price);
    final index = _routePrices.indexWhere((item) => item.id == price.id);
    if (index == -1) throw ArgumentError('Route price not found');
    final model = RoutePackagePriceModel.fromEntity(price);
    _routePrices[index] = model;
    return model;
  }

  void _validateRoutePrice(RoutePackagePriceEntity price) {
    if (price.routeId.isEmpty ||
        price.packagePlanId.isEmpty ||
        price.price <= 0) {
      throw ArgumentError('Invalid route package price');
    }
    final route = _routesById[price.routeId];
    if (route == null) throw ArgumentError('Route not found');
    final from = route.points.firstWhere(
      (point) => point.id == price.fromPointId,
    );
    final to = route.points.firstWhere((point) => point.id == price.toPointId);
    if (from.id == to.id || from.order >= to.order) {
      throw ArgumentError('Invalid route point order');
    }
  }
}

final Map<String, PackageRouteEntity> _routesById = {
  for (final route in const [
    PackageRouteEntity(
      id: 'route-banha-fifth',
      name: 'بنها - التجمع الخامس',
      points: [
        RoutePointEntity(
          id: 'point-banha',
          name: 'بنها',
          latitude: 30.466,
          longitude: 31.184,
          order: 1,
        ),
        RoutePointEntity(
          id: 'point-shubra',
          name: 'شبرا',
          latitude: 30.128,
          longitude: 31.242,
          order: 2,
        ),
        RoutePointEntity(
          id: 'point-ramses',
          name: 'رمسيس',
          latitude: 30.062,
          longitude: 31.247,
          order: 3,
        ),
        RoutePointEntity(
          id: 'point-nasr',
          name: 'مدينة نصر',
          latitude: 30.056,
          longitude: 31.33,
          order: 4,
        ),
        RoutePointEntity(
          id: 'point-fifth',
          name: 'التجمع الخامس',
          latitude: 30.008,
          longitude: 31.428,
          order: 5,
        ),
      ],
    ),
    PackageRouteEntity(
      id: 'route-maadi-capital',
      name: 'المعادي - العاصمة الإدارية',
      points: [
        RoutePointEntity(
          id: 'point-maadi',
          name: 'المعادي',
          latitude: 29.96,
          longitude: 31.25,
          order: 1,
        ),
        RoutePointEntity(
          id: 'point-zahraa',
          name: 'زهراء المعادي',
          latitude: 29.98,
          longitude: 31.31,
          order: 2,
        ),
        RoutePointEntity(
          id: 'point-kattameya',
          name: 'القطامية',
          latitude: 30.02,
          longitude: 31.38,
          order: 3,
        ),
        RoutePointEntity(
          id: 'point-capital',
          name: 'العاصمة الإدارية',
          latitude: 30.01,
          longitude: 31.72,
          order: 4,
        ),
      ],
    ),
  ])
    route.id: route,
};

const _seedPlans = [
  PackagePlanModel(
    id: 'plan-one',
    nameAr: 'رحلة واحدة',
    descriptionAr: 'سعر رحلة واحدة فقط بدون اشتراك.',
    packageType: PackageType.oneTime,
    durationDays: 1,
    rideDays: 1,
    price: 120,
    currency: 'ج.م',
    isActive: true,
    createdAt: '١ يونيو ٢٠٢٦',
    updatedAt: '١ يونيو ٢٠٢٦',
  ),
  PackagePlanModel(
    id: 'plan-five',
    nameAr: 'باقة ٥ أيام',
    descriptionAr: 'مناسبة لأسبوع عمل واحد، ٥ أيام متتالية بدون توقف.',
    packageType: PackageType.fiveDays,
    durationDays: 5,
    rideDays: 5,
    price: 550,
    currency: 'ج.م',
    isActive: true,
    createdAt: '١ يونيو ٢٠٢٦',
    updatedAt: '١ يونيو ٢٠٢٦',
  ),
  PackagePlanModel(
    id: 'plan-ten',
    nameAr: 'باقة ١٠ أيام شهريًا',
    descriptionAr: 'مناسبة لمن يستخدم الخدمة أسبوعين فقط خلال الشهر.',
    packageType: PackageType.tenDaysMonthly,
    durationDays: 30,
    rideDays: 10,
    price: 1000,
    currency: 'ج.م',
    isActive: true,
    createdAt: '١ يونيو ٢٠٢٦',
    updatedAt: '١ يونيو ٢٠٢٦',
  ),
  PackagePlanModel(
    id: 'plan-month',
    nameAr: 'باقة شهر',
    descriptionAr: 'اشتراك شهري كامل على نفس المسار.',
    packageType: PackageType.monthly,
    durationDays: 30,
    rideDays: 22,
    price: 1900,
    currency: 'ج.م',
    isActive: true,
    createdAt: '١ يونيو ٢٠٢٦',
    updatedAt: '١ يونيو ٢٠٢٦',
  ),
  PackagePlanModel(
    id: 'plan-three',
    nameAr: 'باقة ٣ شهور',
    descriptionAr: 'اشتراك طويل المدى بسعر أفضل.',
    packageType: PackageType.threeMonths,
    durationDays: 90,
    rideDays: 66,
    price: 5200,
    currency: 'ج.م',
    isActive: true,
    createdAt: '١ يونيو ٢٠٢٦',
    updatedAt: '١ يونيو ٢٠٢٦',
  ),
];

const _seedRoutePrices = [
  RoutePackagePriceModel(
    id: 'price-full-one',
    routeId: 'route-banha-fifth',
    routeName: 'بنها - التجمع الخامس',
    fromPointId: 'point-banha',
    fromPointName: 'بنها',
    toPointId: 'point-fifth',
    toPointName: 'التجمع الخامس',
    packagePlanId: 'plan-one',
    packageName: 'رحلة واحدة',
    price: 120,
    currency: 'ج.م',
    isActive: true,
  ),
  RoutePackagePriceModel(
    id: 'price-full-five',
    routeId: 'route-banha-fifth',
    routeName: 'بنها - التجمع الخامس',
    fromPointId: 'point-banha',
    fromPointName: 'بنها',
    toPointId: 'point-fifth',
    toPointName: 'التجمع الخامس',
    packagePlanId: 'plan-five',
    packageName: 'باقة ٥ أيام',
    price: 550,
    currency: 'ج.م',
    isActive: true,
  ),
  RoutePackagePriceModel(
    id: 'price-banha-ramses',
    routeId: 'route-banha-fifth',
    routeName: 'بنها - التجمع الخامس',
    fromPointId: 'point-banha',
    fromPointName: 'بنها',
    toPointId: 'point-ramses',
    toPointName: 'رمسيس',
    packagePlanId: 'plan-one',
    packageName: 'رحلة واحدة',
    price: 60,
    currency: 'ج.م',
    isActive: true,
  ),
  RoutePackagePriceModel(
    id: 'price-ramses-fifth',
    routeId: 'route-banha-fifth',
    routeName: 'بنها - التجمع الخامس',
    fromPointId: 'point-ramses',
    fromPointName: 'رمسيس',
    toPointId: 'point-fifth',
    toPointName: 'التجمع الخامس',
    packagePlanId: 'plan-month',
    packageName: 'باقة شهر',
    price: 1050,
    currency: 'ج.م',
    isActive: true,
  ),
];
