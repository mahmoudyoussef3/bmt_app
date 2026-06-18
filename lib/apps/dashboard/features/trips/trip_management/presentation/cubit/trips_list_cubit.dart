import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_management_usecases.dart';

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
  });

  List<OperationTrip> get filteredTrips {
    final query = searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return trips.where((trip) {
      final matchesSearch =
          query.isEmpty ||
          trip.id.toLowerCase().contains(query) ||
          trip.route.toLowerCase().contains(query) ||
          trip.driver.toLowerCase().contains(query) ||
          trip.vehicle.toLowerCase().contains(query);
      final matchesQuick = switch (quickFilter) {
        'today' => trip.date == todayStr,
        'upcoming' =>
          trip.status == OperationTripStatus.scheduled ||
              trip.status == OperationTripStatus.openForBooking,
        'active' =>
          trip.status == OperationTripStatus.boarding ||
              trip.status == OperationTripStatus.inProgress,
        'completed' => trip.status == OperationTripStatus.completed,
        'cancelled' => trip.status == OperationTripStatus.cancelled,
        _ => true,
      };
      final matchesStatus = statusFilter == null || trip.status == statusFilter;
      final matchesRoute = routeFilter == 'الكل' || trip.route == routeFilter;
      final matchesDriver =
          driverFilter == 'الكل' || trip.driver == driverFilter;
      final matchesVehicle =
          vehicleFilter == 'الكل' || trip.vehicle == vehicleFilter;
      final occupancy = trip.capacity == 0
          ? 0
          : trip.bookedSeats / trip.capacity;
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
          matchesQuick &&
          matchesStatus &&
          matchesRoute &&
          matchesDriver &&
          matchesVehicle &&
          matchesOccupancy &&
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

  int get upcomingTrips => trips
      .where(
        (trip) =>
            trip.status == OperationTripStatus.scheduled ||
            trip.status == OperationTripStatus.openForBooking,
      )
      .length;
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
    );
  }
}

class TripsListCubit extends Cubit<TripsListState> {
  final GetOperationTripsUseCase _getTrips;
  final DeleteTripUseCase _deleteTrip;

  TripsListCubit(this._getTrips, this._deleteTrip)
    : super(const TripsListInitial());

  Future<void> load() async {
    emit(const TripsListLoading());
    try {
      final trips = await _getTrips();
      emit(TripsListLoaded(trips: trips));
    } catch (e) {
      emit(TripsListError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  void filterQuick(String quickFilter) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(quickFilter: quickFilter));
  }

  void filterStatus(OperationTripStatus? status) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(
      current.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
  }

  void filterRoute(String route) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(routeFilter: route));
  }

  void filterDriver(String driver) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(driverFilter: driver));
  }

  void filterVehicle(String vehicle) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(vehicleFilter: vehicle));
  }

  void filterOccupancy(String occupancy) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(occupancyFilter: occupancy));
  }

  void filterDate(String date) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(dateFilter: date));
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
}
