import '../../domain/entities/live_trip.dart';

sealed class LiveTripsState {
  const LiveTripsState();
}

class LiveTripsLoading extends LiveTripsState {
  const LiveTripsLoading();
}

class LiveTripsError extends LiveTripsState {
  const LiveTripsError(this.message);
  final String message;
}

class LiveTripsLoaded extends LiveTripsState {
  const LiveTripsLoaded({
    required this.trips,
    required this.selectedTripId,
    this.actionLoading = false,
    this.actionMessage,
    this.filterHealth,
    this.filterStatus,
    this.searchQuery = '',
  });

  final List<LiveTrip> trips;
  final String? selectedTripId;
  final bool actionLoading;
  final String? actionMessage;
  final LiveTripHealth? filterHealth;
  final LiveTripStatus? filterStatus;
  final String searchQuery;

  LiveTrip? get selectedTrip {
    if (selectedTripId == null || trips.isEmpty) return null;
    return trips.where((trip) => trip.id == selectedTripId).firstOrNull;
  }

  List<LiveTrip> get filteredTrips {
    return trips.where((trip) {
      if (filterHealth != null && trip.health != filterHealth) return false;
      if (filterStatus != null && trip.status != filterStatus) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchCode = trip.tripCode.toLowerCase().contains(query);
        final matchRoute = trip.routeName.toLowerCase().contains(query);
        final matchDriver = trip.driverName.toLowerCase().contains(query);
        final matchPlate = trip.vehiclePlate.toLowerCase().contains(query);
        if (!matchCode && !matchRoute && !matchDriver && !matchPlate) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get urgentAlertsCount {
    return trips.fold<int>(
      0,
      (total, trip) => total + trip.criticalAlertsCount,
    );
  }

  int get delayedTripsCount {
    return trips.where((trip) => trip.health.name == 'delayed').length;
  }

  int get unresolvedAlertsCount {
    return trips.fold<int>(
      0,
      (total, trip) => total + trip.unresolvedAlertsCount,
    );
  }

  LiveTripsLoaded copyWith({
    List<LiveTrip>? trips,
    String? selectedTripId,
    bool? actionLoading,
    String? actionMessage,
    bool clearMessage = false,
    LiveTripHealth? filterHealth,
    LiveTripStatus? filterStatus,
    String? searchQuery,
    bool clearHealth = false,
    bool clearStatus = false,
  }) {
    return LiveTripsLoaded(
      trips: trips ?? this.trips,
      selectedTripId: selectedTripId ?? this.selectedTripId,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: clearMessage ? null : actionMessage ?? this.actionMessage,
      filterHealth: clearHealth ? null : filterHealth ?? this.filterHealth,
      filterStatus: clearStatus ? null : filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
