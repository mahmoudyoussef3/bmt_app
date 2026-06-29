import '../../domain/entities/operation_route.dart';

enum RoutesView { list, details, form, success }

enum StopsCountFilter {
  all('كل المحطات'),
  fiveToSeven('٥ - ٧ محطات'),
  eightToTen('٨ - ١٠ محطات');

  final String label;

  const StopsCountFilter(this.label);
}

sealed class RoutesState {
  const RoutesState();
}

class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

class RoutesError extends RoutesState {
  final String message;

  const RoutesError(this.message);
}

class RoutesLoaded extends RoutesState {
  final List<OperationRoute> routes;
  final String selectedRouteId;
  final RoutesView view;
  final OperationRoute? editingRoute;
  final String searchQuery;
  final OperationRouteStatus? statusFilter;
  final String cityFilter;
  final StopsCountFilter stopsFilter;
  final OperationRoute? successRoute;

  const RoutesLoaded({
    required this.routes,
    required this.selectedRouteId,
    this.view = RoutesView.list,
    this.editingRoute,
    this.searchQuery = '',
    this.statusFilter,
    this.cityFilter = 'الكل',
    this.stopsFilter = StopsCountFilter.all,
    this.successRoute,
  });

  OperationRoute get selectedRoute {
    if (routes.isEmpty) {
      return const OperationRoute(
        id: '',
        name: '',
        startCity: '',
        endCity: '',
        duration: '',
        distance: '',
        status: OperationRouteStatus.draft,
        stations: [],
        notes: [],
      );
    }
    final match = routes.where((route) => route.id == selectedRouteId);
    if (match.isEmpty) return routes.first;
    return match.first;
  }

  List<String> get cityOptions {
    final cities =
        routes
            .expand((route) => [route.startCity, route.endCity])
            .toSet()
            .toList()
          ..sort();
    return ['الكل', ...cities];
  }

  List<OperationRoute> get filteredRoutes {
    return routes.where((route) {
      final query = searchQuery.trim();
      final matchesSearch =
          query.isEmpty ||
          route.routeCode.contains(query) ||
          route.name.contains(query) ||
          route.startCity.contains(query) ||
          route.endCity.contains(query);
      final matchesStatus =
          statusFilter == null || route.status == statusFilter;
      final matchesCity =
          cityFilter == 'الكل' ||
          route.startCity == cityFilter ||
          route.endCity == cityFilter;
      final matchesStops = switch (stopsFilter) {
        StopsCountFilter.all => true,
        StopsCountFilter.fiveToSeven =>
          route.stations.length >= 5 && route.stations.length <= 7,
        StopsCountFilter.eightToTen =>
          route.stations.length >= 8 && route.stations.length <= 10,
      };
      return matchesSearch && matchesStatus && matchesCity && matchesStops;
    }).toList();
  }

  RoutesLoaded copyWith({
    List<OperationRoute>? routes,
    String? selectedRouteId,
    RoutesView? view,
    OperationRoute? editingRoute,
    bool clearEditingRoute = false,
    String? searchQuery,
    OperationRouteStatus? statusFilter,
    bool clearStatusFilter = false,
    String? cityFilter,
    StopsCountFilter? stopsFilter,
    OperationRoute? successRoute,
    bool clearSuccessRoute = false,
  }) {
    return RoutesLoaded(
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      view: view ?? this.view,
      editingRoute: clearEditingRoute
          ? null
          : editingRoute ?? this.editingRoute,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      cityFilter: cityFilter ?? this.cityFilter,
      stopsFilter: stopsFilter ?? this.stopsFilter,
      successRoute: clearSuccessRoute
          ? null
          : successRoute ?? this.successRoute,
    );
  }
}
