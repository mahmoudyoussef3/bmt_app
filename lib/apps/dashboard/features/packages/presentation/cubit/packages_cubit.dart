import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/package_pricing.dart';
import '../../domain/usecases/packages_usecases.dart';
import 'packages_state.dart';

class PackagesCubit extends Cubit<PackagesState> {
  final GetPackagePlansUseCase _getPlans;
  final CreatePackagePlanUseCase _createPlan;
  final UpdatePackagePlanUseCase _updatePlan;
  final TogglePackagePlanStatusUseCase _togglePlanStatus;
  final GetPackageRoutesUseCase _getRoutes;
  final GetRoutePackagePricesUseCase _getRoutePrices;
  final AssignPackagePriceToRoutePointsUseCase _assignRoutePrice;
  final UpdateRoutePackagePriceUseCase _updateRoutePrice;
  final GetTripPackagePricesUseCase _getTripPrices;
  final AssignPackagePriceToTripUseCase _assignTripPrice;

  PackagesCubit({
    required GetPackagePlansUseCase getPlans,
    required CreatePackagePlanUseCase createPlan,
    required UpdatePackagePlanUseCase updatePlan,
    required TogglePackagePlanStatusUseCase togglePlanStatus,
    required GetPackageRoutesUseCase getRoutes,
    required GetRoutePackagePricesUseCase getRoutePrices,
    required AssignPackagePriceToRoutePointsUseCase assignRoutePrice,
    required UpdateRoutePackagePriceUseCase updateRoutePrice,
    required GetTripPackagePricesUseCase getTripPrices,
    required AssignPackagePriceToTripUseCase assignTripPrice,
  }) : _getPlans = getPlans,
       _createPlan = createPlan,
       _updatePlan = updatePlan,
       _togglePlanStatus = togglePlanStatus,
       _getRoutes = getRoutes,
       _getRoutePrices = getRoutePrices,
       _assignRoutePrice = assignRoutePrice,
       _updateRoutePrice = updateRoutePrice,
       _getTripPrices = getTripPrices,
       _assignTripPrice = assignTripPrice,
       super(const PackagesInitial());

  Future<void> load() async {
    emit(const PackagesLoading());
    try {
      final plans = await _getPlans();
      final routes = await _getRoutes();
      final selectedRoute = routes.first;
      final routePrices = await _getRoutePrices(selectedRoute.id);
      emit(
        PackagePlansLoaded(
          plans: plans,
          routes: routes,
          selectedRoute: selectedRoute,
          routePrices: routePrices,
        ),
      );
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  void showOverview() {
    final current = state;
    if (current is! PackagePlansLoaded) return;
    emit(current.copyWith(view: PackagesView.overview));
  }

  Future<void> showRoutePricing({PackageRouteEntity? route}) async {
    final current = state;
    if (current is! PackagePlansLoaded) return;
    final selected = route ?? current.selectedRoute;
    final prices = await _getRoutePrices(selected.id);
    emit(
      RoutePackagePricesLoaded(
        plans: current.plans,
        routes: current.routes,
        selectedRoute: selected,
        routePrices: prices,
      ),
    );
  }

  Future<void> savePlan(PackagePlanEntity plan) async {
    final current = state;
    if (current is! PackagePlansLoaded) return;
    try {
      if (plan.id.isEmpty) {
        await _createPlan(plan);
      } else {
        await _updatePlan(plan);
      }
      await _reload(current.view, current.selectedRoute);
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  Future<void> togglePlan(String planId) async {
    final current = state;
    if (current is! PackagePlansLoaded) return;
    try {
      await _togglePlanStatus(planId);
      await _reload(current.view, current.selectedRoute);
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  Future<String?> saveRoutePrice(RoutePackagePriceEntity price) async {
    final current = state;
    if (current is! PackagePlansLoaded) return null;
    try {
      if (price.id.isEmpty) {
        await _assignRoutePrice(price);
      } else {
        await _updateRoutePrice(price);
      }
      await _reload(PackagesView.routePricing, current.selectedRoute);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> loadTripPrices(String tripId) async {
    try {
      emit(TripPackagePricesLoaded(await _getTripPrices(tripId)));
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  Future<void> assignTripPrice(TripPackagePriceEntity price) async {
    try {
      await _assignTripPrice(price);
      emit(const PackagesActionSuccess('تم حفظ سعر الرحلة'));
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  Future<void> _reload(
    PackagesView view,
    PackageRouteEntity selectedRoute,
  ) async {
    final plans = await _getPlans();
    final routes = await _getRoutes();
    final route = routes.firstWhere(
      (item) => item.id == selectedRoute.id,
      orElse: () => routes.first,
    );
    final prices = await _getRoutePrices(route.id);
    emit(
      PackagePlansLoaded(
        plans: plans,
        routes: routes,
        selectedRoute: route,
        routePrices: prices,
        view: view,
      ),
    );
  }
}
