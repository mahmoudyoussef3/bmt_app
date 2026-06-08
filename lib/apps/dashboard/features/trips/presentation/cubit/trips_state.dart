import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';

enum TripWorkspaceTab {
  overview,
  route,
  vehicle,
  driver,
  pricing,
  passengers,
  seats,
  history,
}

sealed class TripsState {
  const TripsState();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsError extends TripsState {
  final String message;

  const TripsError(this.message);
}

class TripsLoaded extends TripsState {
  final List<OperationTrip> trips;
  final OperationTrip? selectedTrip;
  final TripWorkspaceTab tab;
  final String searchQuery;
  final OperationTripStatus? statusFilter;
  final String routeFilter;
  final String driverFilter;
  final String dateFilter;
  final List<TripPricing> selectedTripPricing;
  final bool pricingLoading;
  final String? pricingError;

  const TripsLoaded({
    required this.trips,
    this.selectedTrip,
    this.tab = TripWorkspaceTab.overview,
    this.searchQuery = '',
    this.statusFilter,
    this.routeFilter = 'الكل',
    this.driverFilter = 'الكل',
    this.dateFilter = 'الكل',
    this.selectedTripPricing = const [],
    this.pricingLoading = false,
    this.pricingError,
  });

  List<OperationTrip> get filteredTrips {
    final query = searchQuery.trim();
    return trips.where((trip) {
      final matchesSearch =
          query.isEmpty ||
          trip.id.contains(query) ||
          trip.route.contains(query) ||
          trip.driver.contains(query) ||
          trip.vehicle.contains(query);
      final matchesStatus = statusFilter == null || trip.status == statusFilter;
      final matchesRoute = routeFilter == 'الكل' || trip.route == routeFilter;
      final matchesDriver =
          driverFilter == 'الكل' || trip.driver == driverFilter;
      final matchesDate = dateFilter == 'الكل' || trip.date == dateFilter;
      return matchesSearch &&
          matchesStatus &&
          matchesRoute &&
          matchesDriver &&
          matchesDate;
    }).toList();
  }

  List<String> get routes => [
    'الكل',
    ...trips.map((trip) => trip.route).toSet(),
  ];
  List<String> get drivers => [
    'الكل',
    ...trips.map((trip) => trip.driver).toSet(),
  ];
  List<String> get dates => ['الكل', ...trips.map((trip) => trip.date).toSet()];

  int get todayTrips =>
      trips.where((trip) => trip.date == '٨ يونيو ٢٠٢٦').length;
  int get upcomingTrips => trips
      .where(
        (trip) =>
            trip.status == OperationTripStatus.scheduled ||
            trip.status == OperationTripStatus.openForBooking,
      )
      .length;
  int get runningTrips => trips
      .where((trip) => trip.status == OperationTripStatus.inProgress)
      .length;
  int get completedTrips => trips
      .where((trip) => trip.status == OperationTripStatus.completed)
      .length;

  TripsLoaded copyWith({
    List<OperationTrip>? trips,
    OperationTrip? selectedTrip,
    bool clearSelectedTrip = false,
    TripWorkspaceTab? tab,
    String? searchQuery,
    OperationTripStatus? statusFilter,
    bool clearStatusFilter = false,
    String? routeFilter,
    String? driverFilter,
    String? dateFilter,
    List<TripPricing>? selectedTripPricing,
    bool? pricingLoading,
    String? pricingError,
    bool clearPricingError = false,
  }) {
    return TripsLoaded(
      trips: trips ?? this.trips,
      selectedTrip: clearSelectedTrip
          ? null
          : selectedTrip ?? this.selectedTrip,
      tab: tab ?? this.tab,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      routeFilter: routeFilter ?? this.routeFilter,
      driverFilter: driverFilter ?? this.driverFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      selectedTripPricing: selectedTripPricing ?? this.selectedTripPricing,
      pricingLoading: pricingLoading ?? this.pricingLoading,
      pricingError: clearPricingError
          ? null
          : pricingError ?? this.pricingError,
    );
  }
}
