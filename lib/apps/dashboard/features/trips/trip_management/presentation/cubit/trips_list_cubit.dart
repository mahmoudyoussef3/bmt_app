import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

/// Rows per page in the trips table — matches the row count the office sees
/// before paging, same order of magnitude as [customersPageSize].
const int tripsPageSize = 20;

String _ymd(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// How the loaded trips are laid out on screen.
enum TripsViewMode {
  /// Single list driven by the [TripsListLoaded.quickFilter] chip.
  list,

  /// Always-visible sections: upcoming / active / completed (+ stale /
  /// cancelled when non-empty), each independently filtered by search and
  /// the advanced filters.
  grouped,

  /// Chronological, date-grouped view of the current quick-filtered set.
  timeline,
}

sealed class TripsListState {
  const TripsListState();
}

class TripsListInitial extends TripsListState {
  const TripsListInitial();
}

class TripsListLoading extends TripsListState {
  const TripsListLoading();
}

class TripsListError extends TripsListState {
  final String message;
  const TripsListError(this.message);
}

class TripsListLoaded extends TripsListState {
  final List<OperationTrip> trips;
  final String searchQuery;
  final String quickFilter;
  final OperationTripStatus? statusFilter;
  final String routeFilter;
  final String driverFilter;
  final String vehicleFilter;
  final String occupancyFilter;
  final String dateFilter;
  final TripsViewMode viewMode;

  /// Zero-based page into [filteredTrips], reset to `0` by every filter/search
  /// change so the operator never lands on a page a narrower filter emptied.
  final int pageIndex;

  /// True when the query came back full at [DashboardQueryCaps.trips], so the
  /// planner is showing the newest slice of the schedule rather than every trip
  /// the office has ever run.
  bool get capReached => trips.length >= DashboardQueryCaps.trips;

  const TripsListLoaded({
    required this.trips,
    this.searchQuery = '',
    this.quickFilter = 'all',
    this.statusFilter,
    this.routeFilter = 'الكل',
    this.driverFilter = 'الكل',
    this.vehicleFilter = 'الكل',
    this.occupancyFilter = 'الكل',
    this.dateFilter = 'الكل',
    this.viewMode = TripsViewMode.list,
    this.pageIndex = 0,
  });

  bool _matchesSearchAndAdvancedFilters(OperationTrip trip) {
    final query = searchQuery.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        trip.id.toLowerCase().contains(query) ||
        trip.route.toLowerCase().contains(query) ||
        trip.driver.toLowerCase().contains(query) ||
        trip.vehicle.toLowerCase().contains(query);
    final matchesStatus = statusFilter == null || trip.status == statusFilter;
    final matchesRoute = routeFilter == 'الكل' || trip.route == routeFilter;
    final matchesDriver = driverFilter == 'الكل' || trip.driver == driverFilter;
    final matchesVehicle =
        vehicleFilter == 'الكل' || trip.vehicle == vehicleFilter;
    final occupancy = trip.capacity == 0 ? 0 : trip.bookedSeats / trip.capacity;
    final matchesOccupancy = switch (occupancyFilter) {
      'فارغة' => trip.bookedSeats == 0,
      'أقل من 50%' => occupancy > 0 && occupancy < 0.5,
      '50% - 80%' => occupancy >= 0.5 && occupancy < 0.8,
      'ممتلئة تقريباً' => occupancy >= 0.8 && trip.availableSeats > 0,
      'ممتلئة' => trip.availableSeats == 0 && trip.capacity > 0,
      _ => true,
    };
    final matchesDate = dateFilter == 'الكل' || trip.date == dateFilter;
    return matchesSearch &&
        matchesStatus &&
        matchesRoute &&
        matchesDriver &&
        matchesVehicle &&
        matchesOccupancy &&
        matchesDate;
  }

  /// True when any filter beyond the default quick chip is narrowing the
  /// list — drives the filter button's active badge.
  bool get hasAdvancedFilters =>
      statusFilter != null ||
      routeFilter != 'الكل' ||
      driverFilter != 'الكل' ||
      vehicleFilter != 'الكل' ||
      occupancyFilter != 'الكل' ||
      dateFilter != 'الكل';

  List<OperationTrip> get filteredTrips {
    final now = DateTime.now();
    final todayStr = _ymd(now);
    final tomorrowStr = _ymd(now.add(const Duration(days: 1)));
    return trips.where((trip) {
      final matchesQuick = switch (quickFilter) {
        'today' => trip.date == todayStr,
        'tomorrow' => trip.date == tomorrowStr,
        'noDriver' => trip.driverId.isEmpty && !_isTerminal(trip.status),
        'upcoming' =>
          (trip.status == OperationTripStatus.scheduled ||
                  trip.status == OperationTripStatus.openForBooking) &&
              !trip.isStaleBooking(now: now),
        'stale' => trip.isStaleBooking(now: now),
        'active' =>
          trip.status == OperationTripStatus.boarding ||
              trip.status == OperationTripStatus.inProgress,
        'completed' => trip.status == OperationTripStatus.completed,
        'cancelled' => trip.status == OperationTripStatus.cancelled,
        _ => true,
      };
      return matchesQuick && _matchesSearchAndAdvancedFilters(trip);
    }).toList();
  }

  /// The current page of [filteredTrips], sliced at [tripsPageSize].
  List<OperationTrip> get pagedTrips {
    final all = filteredTrips;
    final start = pageIndex * tripsPageSize;
    if (start >= all.length) return const [];
    return all.sublist(start, (start + tripsPageSize).clamp(0, all.length));
  }

  int get pageCount =>
      (filteredTrips.length / tripsPageSize).ceil().clamp(1, 9999);

  List<OperationTrip> _sortedByDeparture(Iterable<OperationTrip> source) {
    final list = source.toList();
    list.sort((a, b) {
      final aTime = a.scheduledAt;
      final bTime = b.scheduledAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });
    return list;
  }

  /// Trips respecting search + advanced filters only (ignores the quick
  /// filter chip), used as the base set for the grouped view's sections.
  List<OperationTrip> get advancedFilteredTrips =>
      trips.where(_matchesSearchAndAdvancedFilters).toList();

  List<OperationTrip> get upcomingGroupTrips => _sortedByDeparture(
    advancedFilteredTrips.where(
      (trip) =>
          (trip.status == OperationTripStatus.scheduled ||
              trip.status == OperationTripStatus.openForBooking) &&
          !trip.isStaleBooking(),
    ),
  );

  List<OperationTrip> get activeGroupTrips => _sortedByDeparture(
    advancedFilteredTrips.where(
      (trip) =>
          trip.status == OperationTripStatus.boarding ||
          trip.status == OperationTripStatus.inProgress,
    ),
  );

  List<OperationTrip> get completedGroupTrips => _sortedByDeparture(
    advancedFilteredTrips.where(
      (trip) => trip.status == OperationTripStatus.completed,
    ),
  );

  List<OperationTrip> get staleGroupTrips => _sortedByDeparture(
    advancedFilteredTrips.where((trip) => trip.isStaleBooking()),
  );

  List<OperationTrip> get cancelledGroupTrips => _sortedByDeparture(
    advancedFilteredTrips.where(
      (trip) => trip.status == OperationTripStatus.cancelled,
    ),
  );

  /// The current quick-filtered + searched set, ordered chronologically and
  /// grouped by day in the timeline view.
  List<OperationTrip> get timelineTrips => _sortedByDeparture(filteredTrips);

  List<String> get routes => [
    'الكل',
    ...trips.map((trip) => trip.route).toSet(),
  ];
  List<String> get drivers => [
    'الكل',
    ...trips.map((trip) => trip.driver).toSet(),
  ];
  List<String> get vehicles => [
    'الكل',
    ...trips.map((trip) => trip.vehicle).toSet(),
  ];
  List<String> get dates => ['الكل', ...trips.map((trip) => trip.date).toSet()];
  List<String> get occupancyBands => const [
    'الكل',
    'فارغة',
    'أقل من 50%',
    '50% - 80%',
    'ممتلئة تقريباً',
    'ممتلئة',
  ];

  int get todayTrips {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return trips.where((trip) => trip.date == todayStr).length;
  }

  /// Trips still ahead of us. Past-dated trips are excluded even while they sit
  /// on an open status: passengers cannot see them, so counting them here
  /// overstated the bookable inventory. They are surfaced by [staleTrips].
  int get upcomingTrips => trips
      .where(
        (trip) =>
            (trip.status == OperationTripStatus.scheduled ||
                trip.status == OperationTripStatus.openForBooking) &&
            !trip.isStaleBooking(),
      )
      .length;

  /// Open trips whose departure day has already passed — invisible to clients
  /// and awaiting an operator decision.
  int get staleTrips => trips.where((trip) => trip.isStaleBooking()).length;
  int get runningTrips => trips
      .where(
        (trip) =>
            trip.status == OperationTripStatus.boarding ||
            trip.status == OperationTripStatus.inProgress,
      )
      .length;
  int get completedTrips => trips
      .where((trip) => trip.status == OperationTripStatus.completed)
      .length;

  int get tomorrowTrips {
    final tomorrowStr = _ymd(DateTime.now().add(const Duration(days: 1)));
    return trips.where((trip) => trip.date == tomorrowStr).length;
  }

  /// Trips that still need a driver assigned before they can run — excludes
  /// trips that are already done or cancelled, since those need nothing.
  int get needsDriverTrips => trips
      .where((trip) => trip.driverId.isEmpty && !_isTerminal(trip.status))
      .length;

  int get cancelledTrips => trips
      .where((trip) => trip.status == OperationTripStatus.cancelled)
      .length;

  int get cancelledTodayTrips {
    final todayStr = _ymd(DateTime.now());
    return trips
        .where(
          (trip) =>
              trip.date == todayStr &&
              trip.status == OperationTripStatus.cancelled,
        )
        .length;
  }

  /// Average seat occupancy across today's trips with a known capacity, as a
  /// whole percentage. `null` when there is nothing to average — an empty
  /// schedule has no occupancy rate, not a zero one.
  int? get averageOccupancyToday {
    final todayStr = _ymd(DateTime.now());
    final eligible = trips.where(
      (trip) => trip.date == todayStr && trip.capacity > 0,
    );
    if (eligible.isEmpty) return null;
    final sum = eligible
        .map((trip) => trip.bookedSeats / trip.capacity)
        .reduce((a, b) => a + b);
    return (sum / eligible.length * 100).round();
  }

  static bool _isTerminal(OperationTripStatus status) =>
      status == OperationTripStatus.completed ||
      status == OperationTripStatus.cancelled;

  TripsListLoaded copyWith({
    List<OperationTrip>? trips,
    String? searchQuery,
    String? quickFilter,
    OperationTripStatus? statusFilter,
    bool clearStatusFilter = false,
    String? routeFilter,
    String? driverFilter,
    String? vehicleFilter,
    String? occupancyFilter,
    String? dateFilter,
    TripsViewMode? viewMode,
    int? pageIndex,
  }) {
    return TripsListLoaded(
      trips: trips ?? this.trips,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilter: quickFilter ?? this.quickFilter,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      routeFilter: routeFilter ?? this.routeFilter,
      driverFilter: driverFilter ?? this.driverFilter,
      vehicleFilter: vehicleFilter ?? this.vehicleFilter,
      occupancyFilter: occupancyFilter ?? this.occupancyFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      viewMode: viewMode ?? this.viewMode,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class TripsListCubit extends Cubit<TripsListState> {
  final GetOperationTripsUseCase _getTrips;
  final DeleteTripUseCase _deleteTrip;
  final WatchOperationTripsUseCase _watchTrips;

  StreamSubscription<void>? _tripsSub;
  Timer? _refreshTimer;
  Timer? _realtimeRefreshDebounce;
  bool _refreshingFromSource = false;

  TripsListCubit(this._getTrips, this._deleteTrip, this._watchTrips)
    : super(const TripsListInitial());

  @override
  Future<void> close() {
    _tripsSub?.cancel();
    _refreshTimer?.cancel();
    _realtimeRefreshDebounce?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const TripsListLoading());
    try {
      final trips = await _getTrips();
      emit(TripsListLoaded(trips: trips));
      _subscribeToChanges();
      _startPeriodicRefresh();
    } catch (e) {
      emit(TripsListError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(searchQuery: query, pageIndex: 0));
  }

  void filterQuick(String quickFilter) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(quickFilter: quickFilter, pageIndex: 0));
  }

  void setPage(int pageIndex) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(pageIndex: pageIndex));
  }

  void filterStatus(OperationTripStatus? status) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(
      current.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        pageIndex: 0,
      ),
    );
  }

  void filterRoute(String route) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(routeFilter: route, pageIndex: 0));
  }

  void filterDriver(String driver) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(driverFilter: driver, pageIndex: 0));
  }

  void filterVehicle(String vehicle) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(vehicleFilter: vehicle, pageIndex: 0));
  }

  void filterOccupancy(String occupancy) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(occupancyFilter: occupancy, pageIndex: 0));
  }

  void filterDate(String date) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(dateFilter: date, pageIndex: 0));
  }

  void changeViewMode(TripsViewMode mode) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(viewMode: mode));
  }

  void clearAdvancedFilters() {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(
      current.copyWith(
        clearStatusFilter: true,
        routeFilter: 'الكل',
        driverFilter: 'الكل',
        vehicleFilter: 'الكل',
        occupancyFilter: 'الكل',
        dateFilter: 'الكل',
        pageIndex: 0,
      ),
    );
  }

  void appendTrip(OperationTrip trip) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(trips: [trip, ...current.trips]));
  }

  void updateTripInList(OperationTrip updated) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(
      current.copyWith(
        trips: current.trips
            .map((t) => t.id == updated.id ? updated : t)
            .toList(),
      ),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    final current = state;
    if (current is! TripsListLoaded) return;
    try {
      await _deleteTrip(tripId);
      emit(
        current.copyWith(
          trips: current.trips.where((trip) => trip.id != tripId).toList(),
        ),
      );
    } catch (e) {
      emit(TripsListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _subscribeToChanges() {
    _tripsSub?.cancel();
    _tripsSub = _watchTrips().listen((_) {
      _realtimeRefreshDebounce?.cancel();
      _realtimeRefreshDebounce = Timer(
        const Duration(milliseconds: 250),
        _refreshFromSource,
      );
    }, onError: (_) {});
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _refreshFromSource();
    });
  }

  Future<void> _refreshFromSource() async {
    if (_refreshingFromSource || state is! TripsListLoaded) return;
    _refreshingFromSource = true;
    try {
      final trips = await _getTrips();
      final current = state;
      if (current is! TripsListLoaded) return;
      emit(current.copyWith(trips: trips));
    } catch (_) {
    } finally {
      _refreshingFromSource = false;
    }
  }
}
