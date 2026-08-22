import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/services/route_stop_library.dart';

/// The routes module has three surfaces: the board of routes, one route's
/// detail page, and the builder that creates or edits a route.
///
/// There used to be a fourth — a full-page "route created" takeover. Creating a
/// route now lands on that route's detail page with a confirmation toast, which
/// is where the operator's next action (add trips, review stops) actually is.
enum RoutesView { list, details, form }

/// Rows per page on the routes board's table — same figure [tripsPageSize]
/// uses, so pagination feels identical across the console's table modules.
const int routesPageSize = 20;

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

  /// Every trip in the office, loaded alongside [routes] purely so the board
  /// can show real weekly-trip counts, occupancy and price per route instead
  /// of stats no `operation_routes` row actually stores. A trips-feed failure
  /// does not fail this load — see [RoutesCubit.load] — so this can be empty
  /// even when [routes] loaded fine; every stat below degrades to "—" rather
  /// than guessing.
  final List<OperationTrip> trips;
  final String selectedRouteId;
  final RoutesView view;
  final OperationRoute? editingRoute;

  /// Set when the builder was opened to build the *return leg* of this route.
  /// The builder starts from its stops reversed; saving creates a second route
  /// and never touches this one.
  final OperationRoute? reverseOf;
  final String searchQuery;
  final OperationRouteStatus? statusFilter;

  /// Zero-indexed current page of [filteredRoutes] on the board's table.
  final int pageIndex;

  /// A write is in flight (saving the builder, archiving, deleting).
  final bool saving;

  /// A failed *action*. Kept beside the loaded data instead of replacing the
  /// screen with an error state, because dropping the builder would throw away
  /// everything the operator just entered.
  final String actionError;

  /// One-shot confirmation for the UI to surface as a toast.
  final String flashMessage;

  RoutesLoaded({
    required this.routes,
    this.trips = const [],
    required this.selectedRouteId,
    this.view = RoutesView.list,
    this.editingRoute,
    this.reverseOf,
    this.searchQuery = '',
    this.statusFilter,
    this.pageIndex = 0,
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

  /// The current page of [filteredRoutes] on the board's table.
  List<OperationRoute> get pagedRoutes {
    final all = filteredRoutes;
    final start = pageIndex * routesPageSize;
    if (start >= all.length) return const [];
    return all.sublist(start, (start + routesPageSize).clamp(0, all.length));
  }

  int get pageCount =>
      (filteredRoutes.length / routesPageSize).ceil().clamp(1, 9999);

  /// Every route's trips, grouped once per state so the board doesn't rescan
  /// [trips] once per row on every build.
  late final Map<String, List<OperationTrip>> _tripsByRouteId = () {
    final byRoute = <String, List<OperationTrip>>{};
    for (final trip in trips) {
      if (trip.routeId.isEmpty) continue;
      byRoute.putIfAbsent(trip.routeId, () => []).add(trip);
    }
    return byRoute;
  }();

  /// Real, derived numbers for one route — never a fabricated figure. Empty
  /// where the trips feed has nothing to compute one from.
  RouteStats statsFor(OperationRoute route) {
    final routeTrips = _tripsByRouteId[route.id] ?? const [];
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    final occupancyWindowStart = now.subtract(const Duration(days: 30));

    var weeklyTrips = 0;
    var bookedInWindow = 0;
    var capacityInWindow = 0;
    OperationTrip? priceTrip;

    for (final trip in routeTrips) {
      if (trip.status == OperationTripStatus.cancelled) continue;
      final at = trip.scheduledAt;
      if (at == null) continue;

      if (!at.isBefore(now) && at.isBefore(weekAhead)) weeklyTrips++;

      if (!at.isBefore(occupancyWindowStart) && trip.capacity > 0) {
        bookedInWindow += trip.bookedSeats;
        capacityInWindow += trip.capacity;
      }

      // The soonest upcoming trip prices the route today; with none
      // upcoming, the most recent past trip is the best available answer.
      final current = priceTrip?.scheduledAt;
      final isUpcoming = !at.isBefore(now);
      if (current == null) {
        priceTrip = trip;
      } else {
        final currentIsUpcoming = !current.isBefore(now);
        final better = isUpcoming && !currentIsUpcoming
            ? true
            : isUpcoming == currentIsUpcoming &&
                  (isUpcoming ? at.isBefore(current) : at.isAfter(current));
        if (better) priceTrip = trip;
      }
    }

    return RouteStats(
      weeklyTrips: weeklyTrips,
      occupancyRate: capacityInWindow == 0
          ? null
          : bookedInWindow / capacityInWindow,
      price: priceTrip?.ticketPrice,
      currency: priceTrip?.currency ?? 'ج.م',
    );
  }

  /// Every stop across every route — the board's "محطات التحميل" figure.
  int get totalStations =>
      routes.fold(0, (sum, route) => sum + route.stations.length);

  /// The route with the lowest and highest computed occupancy, for the
  /// board's two extreme KPI tiles. `null` when no route has a computable
  /// occupancy (no trips feed, or nothing scheduled in the window).
  (OperationRoute route, double rate)? get lowestOccupancyRoute =>
      _occupancyExtreme(lowest: true);

  (OperationRoute route, double rate)? get highestOccupancyRoute =>
      _occupancyExtreme(lowest: false);

  (OperationRoute route, double rate)? _occupancyExtreme({
    required bool lowest,
  }) {
    (OperationRoute, double)? best;
    for (final route in routes) {
      final rate = statsFor(route).occupancyRate;
      if (rate == null) continue;
      if (best == null || (lowest ? rate < best.$2 : rate > best.$2)) {
        best = (route, rate);
      }
    }
    return best;
  }

  RoutesLoaded copyWith({
    List<OperationRoute>? routes,
    List<OperationTrip>? trips,
    String? selectedRouteId,
    RoutesView? view,
    OperationRoute? editingRoute,
    bool clearEditingRoute = false,
    OperationRoute? reverseOf,
    bool clearReverseOf = false,
    String? searchQuery,
    OperationRouteStatus? statusFilter,
    bool clearStatusFilter = false,
    int? pageIndex,
    bool? saving,
    String? actionError,
    String? flashMessage,
  }) {
    return RoutesLoaded(
      routes: routes ?? this.routes,
      trips: trips ?? this.trips,
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
      pageIndex: pageIndex ?? this.pageIndex,
      saving: saving ?? this.saving,

      actionError: actionError ?? '',
      flashMessage: flashMessage ?? '',
    );
  }
}

/// One route's real, trip-derived numbers — see [RoutesLoaded.statsFor].
class RouteStats {
  /// Trips scheduled between now and 7 days from now, excluding cancelled.
  final int weeklyTrips;

  /// Booked ÷ capacity across trips in the last 30 days plus everything still
  /// ahead, excluding cancelled and zero-capacity trips. `null` when there is
  /// nothing to divide.
  final double? occupancyRate;

  /// The soonest upcoming trip's fare, or the most recent past trip's fare
  /// when nothing is upcoming. `null` when the route has no trips at all.
  final double? price;
  final String currency;

  const RouteStats({
    required this.weeklyTrips,
    required this.occupancyRate,
    required this.price,
    required this.currency,
  });
}
