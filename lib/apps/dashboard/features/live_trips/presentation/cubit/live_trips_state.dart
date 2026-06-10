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
  });

  final List<LiveTrip> trips;
  final String? selectedTripId;
  final bool actionLoading;
  final String? actionMessage;

  LiveTrip? get selectedTrip {
    if (selectedTripId == null || trips.isEmpty) return null;
    return trips.where((trip) => trip.id == selectedTripId).firstOrNull;
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
  }) {
    return LiveTripsLoaded(
      trips: trips ?? this.trips,
      selectedTripId: selectedTripId ?? this.selectedTripId,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: clearMessage ? null : actionMessage ?? this.actionMessage,
    );
  }
}
