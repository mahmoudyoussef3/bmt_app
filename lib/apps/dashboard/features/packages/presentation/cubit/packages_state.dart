import '../../domain/entities/package_pricing.dart';

enum PackagesView { overview, routePricing }

sealed class PackagesState {
  const PackagesState();
}

class PackagesInitial extends PackagesState {
  const PackagesInitial();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagePlansLoaded extends PackagesState {
  final List<PackagePlanEntity> plans;
  final List<PackageRouteEntity> routes;
  final PackageRouteEntity selectedRoute;
  final List<RoutePackagePriceEntity> routePrices;
  final PackagesView view;

  const PackagePlansLoaded({
    required this.plans,
    required this.routes,
    required this.selectedRoute,
    required this.routePrices,
    this.view = PackagesView.overview,
  });

  PackagePlansLoaded copyWith({
    List<PackagePlanEntity>? plans,
    List<PackageRouteEntity>? routes,
    PackageRouteEntity? selectedRoute,
    List<RoutePackagePriceEntity>? routePrices,
    PackagesView? view,
  }) {
    return PackagePlansLoaded(
      plans: plans ?? this.plans,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      routePrices: routePrices ?? this.routePrices,
      view: view ?? this.view,
    );
  }
}

class RoutePackagePricesLoaded extends PackagePlansLoaded {
  const RoutePackagePricesLoaded({
    required super.plans,
    required super.routes,
    required super.selectedRoute,
    required super.routePrices,
    super.view = PackagesView.routePricing,
  });
}

class TripPackagePricesLoaded extends PackagesState {
  final List<TripPackagePriceEntity> prices;

  const TripPackagePricesLoaded(this.prices);
}

class PackagesActionSuccess extends PackagesState {
  final String message;

  const PackagesActionSuccess(this.message);
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError(this.message);
}
