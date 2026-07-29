import '../../domain/entities/operation_route.dart';

/// The routes module has three surfaces: the board of routes, one route's
/// operations detail, and the builder that creates or edits a route.
///
/// There used to be a fourth — a full-page "route created" takeover. Creating a
/// route now lands on that route's detail page with a confirmation toast, which
/// is where the operator's next action (add trips, review stops) actually is.
enum RoutesView { list, details, form }

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

  /// A write is in flight (saving the builder, archiving, deleting).
  final bool saving;

  /// A failed *action*. Kept beside the loaded data instead of replacing the
  /// screen with an error state, because dropping the builder would throw away
  /// everything the operator just entered.
  final String actionError;

  /// One-shot confirmation for the UI to surface as a toast.
  final String flashMessage;

  const RoutesLoaded({
    required this.routes,
    required this.selectedRouteId,
    this.view = RoutesView.list,
    this.editingRoute,
    this.searchQuery = '',
    this.statusFilter,
    this.cityFilter = 'الكل',
    this.stopsFilter = StopsCountFilter.all,
    this.saving = false,
    this.actionError = '',
    this.flashMessage = '',
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

  /// Codes already taken, so the builder can reserve the next free one.
  List<String> get routeCodes =>
      routes.map((route) => route.routeCode).where((code) => code.isNotEmpty).toList();

  List<String> get cityOptions {
    final cities =
        routes
            .expand((route) => [route.startCity, route.endCity])
            .where((city) => city.isNotEmpty)
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
    bool? saving,
    String? actionError,
    String? flashMessage,
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
      saving: saving ?? this.saving,
      // Transient by design: any state change that does not explicitly restate
      // them clears them, so a stale error can never outlive the action.
      actionError: actionError ?? '',
      flashMessage: flashMessage ?? '',
    );
  }
}
