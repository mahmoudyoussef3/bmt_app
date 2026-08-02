import '../../domain/entities/operation_route.dart';
import '../../domain/services/route_stop_library.dart';

/// The routes module has three surfaces: the board of routes, one route's
/// detail page, and the builder that creates or edits a route.
///
/// There used to be a fourth — a full-page "route created" takeover. Creating a
/// route now lands on that route's detail page with a confirmation toast, which
/// is where the operator's next action (add trips, review stops) actually is.
enum RoutesView { list, details, form }

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

  /// Set when the builder was opened to build the *return leg* of this route.
  /// The builder starts from its stops reversed; saving creates a second route
  /// and never touches this one.
  final OperationRoute? reverseOf;
  final String searchQuery;
  final OperationRouteStatus? statusFilter;

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
    this.reverseOf,
    this.searchQuery = '',
    this.statusFilter,
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
  List<String> get routeCodes => routes
      .map((route) => route.routeCode)
      .where((code) => code.isNotEmpty)
      .toList();

  /// Every stop the office already uses, offered when a new one is added so the
  /// same place is not retyped into four spellings.
  RouteStopLibrary get stopLibrary => RouteStopLibrary.fromRoutes(routes);

  int get activeCount => routes
      .where((route) => route.status == OperationRouteStatus.active)
      .length;

  int get pausedCount => routes
      .where((route) => route.status == OperationRouteStatus.paused)
      .length;

  /// Search matches the route's name, code, endpoints *and* every stop on the
  /// way — an operator looking for "the line through Mostorod" is looking for a
  /// stop, not a route name.
  List<OperationRoute> get filteredRoutes {
    final query = searchQuery.trim();
    return routes.where((route) {
      final matchesSearch =
          query.isEmpty ||
          route.routeCode.contains(query) ||
          route.name.contains(query) ||
          route.startCity.contains(query) ||
          route.endCity.contains(query) ||
          route.stations.any((station) => station.name.contains(query));
      final matchesStatus =
          statusFilter == null || route.status == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  RoutesLoaded copyWith({
    List<OperationRoute>? routes,
    String? selectedRouteId,
    RoutesView? view,
    OperationRoute? editingRoute,
    bool clearEditingRoute = false,
    OperationRoute? reverseOf,
    bool clearReverseOf = false,
    String? searchQuery,
    OperationRouteStatus? statusFilter,
    bool clearStatusFilter = false,
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
      reverseOf: clearReverseOf ? null : reverseOf ?? this.reverseOf,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      saving: saving ?? this.saving,
      // Transient by design: any state change that does not explicitly restate
      // them clears them, so a stale error can never outlive the action.
      actionError: actionError ?? '',
      flashMessage: flashMessage ?? '',
    );
  }
}
