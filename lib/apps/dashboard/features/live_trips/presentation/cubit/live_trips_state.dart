import '../../domain/entities/live_trip.dart';

sealed class LiveTripsState {
  const LiveTripsState();
}

class LiveTripsLoading extends LiveTripsState {
  const LiveTripsLoading();
}

class LiveTripsError extends LiveTripsState {
  final String message;

  const LiveTripsError(this.message);
}

class LiveTripsLoaded extends LiveTripsState {
  final List<LiveTrip> trips;
  final String selectedTripId;

  const LiveTripsLoaded({required this.trips, required this.selectedTripId});

  LiveTrip get selectedTrip {
    return trips.firstWhere(
      (trip) => trip.id == selectedTripId,
      orElse: () => trips.first,
    );
  }

  int get urgentAlertsCount {
    return trips
        .expand((trip) => trip.alerts)
        .where((alert) => alert.urgent)
        .length;
  }

  LiveTripsLoaded copyWith({List<LiveTrip>? trips, String? selectedTripId}) {
    return LiveTripsLoaded(
      trips: trips ?? this.trips,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}
