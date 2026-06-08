import '../entities/package_pricing.dart';
import '../repositories/packages_repository.dart';

class GetPackagePlansUseCase {
  final PackagesRepository _repository;
  const GetPackagePlansUseCase(this._repository);
  Future<List<PackagePlanEntity>> call() => _repository.getPackagePlans();
}

class CreatePackagePlanUseCase {
  final PackagesRepository _repository;
  const CreatePackagePlanUseCase(this._repository);
  Future<PackagePlanEntity> call(PackagePlanEntity plan) {
    return _repository.createPackagePlan(plan);
  }
}

class UpdatePackagePlanUseCase {
  final PackagesRepository _repository;
  const UpdatePackagePlanUseCase(this._repository);
  Future<PackagePlanEntity> call(PackagePlanEntity plan) {
    return _repository.updatePackagePlan(plan);
  }
}

class TogglePackagePlanStatusUseCase {
  final PackagesRepository _repository;
  const TogglePackagePlanStatusUseCase(this._repository);
  Future<PackagePlanEntity> call(String planId) {
    return _repository.togglePackagePlanStatus(planId);
  }
}

class GetPackageRoutesUseCase {
  final PackagesRepository _repository;
  const GetPackageRoutesUseCase(this._repository);
  Future<List<PackageRouteEntity>> call() => _repository.getRoutes();
}

class GetRoutePackagePricesUseCase {
  final PackagesRepository _repository;
  const GetRoutePackagePricesUseCase(this._repository);
  Future<List<RoutePackagePriceEntity>> call(String routeId) {
    return _repository.getRoutePackagePrices(routeId);
  }
}

class AssignPackagePriceToRoutePointsUseCase {
  final PackagesRepository _repository;
  const AssignPackagePriceToRoutePointsUseCase(this._repository);
  Future<RoutePackagePriceEntity> call(RoutePackagePriceEntity price) {
    return _repository.assignPackagePriceToRoutePoints(price);
  }
}

class UpdateRoutePackagePriceUseCase {
  final PackagesRepository _repository;
  const UpdateRoutePackagePriceUseCase(this._repository);
  Future<RoutePackagePriceEntity> call(RoutePackagePriceEntity price) {
    return _repository.updateRoutePackagePrice(price);
  }
}

class GetTripPackagePricesUseCase {
  final PackagesRepository _repository;
  const GetTripPackagePricesUseCase(this._repository);
  Future<List<TripPackagePriceEntity>> call(String tripId) {
    return _repository.getTripPackagePrices(tripId);
  }
}

class AssignPackagePriceToTripUseCase {
  final PackagesRepository _repository;
  const AssignPackagePriceToTripUseCase(this._repository);
  Future<TripPackagePriceEntity> call(TripPackagePriceEntity price) {
    return _repository.assignPackagePriceToTrip(price);
  }
}
