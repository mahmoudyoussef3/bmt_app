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
  final OperationTripStatus? statusFilter;
  final String routeFilter;
  final String driverFilter;
  final String dateFilter;

  const TripsListLoaded({
    required this.trips,
    this.searchQuery = '',
    this.statusFilter,
    this.routeFilter = 'الكل',
    this.driverFilter = 'الكل',
    this.dateFilter = 'الكل',
  });

  List<OperationTrip> get filteredTrips {
    final query = searchQuery.trim();
    return trips.where((trip) {
      final matchesSearch = query.isEmpty ||
          trip.id.contains(query) ||
          trip.route.contains(query) ||
          trip.driver.contains(query) ||
          trip.vehicle.contains(query);
      final matchesStatus = statusFilter == null || trip.status == statusFilter;
      final matchesRoute = routeFilter == 'الكل' || trip.route == routeFilter;
      final matchesDriver = driverFilter == 'الكل' || trip.driver == driverFilter;
      final matchesDate = dateFilter == 'الكل' || trip.date == dateFilter;
      return matchesSearch && matchesStatus && matchesRoute && matchesDriver && matchesDate;
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
  List<String> get dates => [
        'الكل',
        ...trips.map((trip) => trip.date).toSet(),
      ];

  int get todayTrips {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return trips.where((trip) => trip.date == todayStr).length;
  }
  int get upcomingTrips => trips
      .where((trip) =>
          trip.status == OperationTripStatus.scheduled ||
          trip.status == OperationTripStatus.openForBooking)
      .length;
  int get runningTrips =>
      trips.where((trip) => trip.status == OperationTripStatus.inProgress).length;
  int get completedTrips =>
      trips.where((trip) => trip.status == OperationTripStatus.completed).length;

  TripsListLoaded copyWith({
    List<OperationTrip>? trips,
    String? searchQuery,
    OperationTripStatus? statusFilter,
    bool clearStatusFilter = false,
    String? routeFilter,
    String? driverFilter,
    String? dateFilter,
  }) {
    return TripsListLoaded(
      trips: trips ?? this.trips,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      routeFilter: routeFilter ?? this.routeFilter,
      driverFilter: driverFilter ?? this.driverFilter,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

class TripsListCubit extends Cubit<TripsListState> {
  final GetOperationTripsUseCase _getTrips;

  TripsListCubit(this._getTrips) : super(const TripsListInitial());

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

  void filterStatus(OperationTripStatus? status) {
    final current = state;
    if (current is! TripsListLoaded) return;
    emit(current.copyWith(statusFilter: status, clearStatusFilter: status == null));
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
    emit(current.copyWith(
      trips: current.trips.map((t) => t.id == updated.id ? updated : t).toList(),
    ));
  }
}
