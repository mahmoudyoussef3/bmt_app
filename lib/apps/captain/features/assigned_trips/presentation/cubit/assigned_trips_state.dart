import '../../domain/entities/assigned_trip.dart';

sealed class AssignedTripsState {
  const AssignedTripsState();
}

class AssignedTripsLoading extends AssignedTripsState {
  const AssignedTripsLoading();
}

class AssignedTripsLoaded extends AssignedTripsState {
  const AssignedTripsLoaded(
    this.trips, {
    this.newTripIds = const {},
    this.isRefreshing = false,
  });

  final List<AssignedTrip> trips;

  final Set<String> newTripIds;

  final bool isRefreshing;

  AssignedTripsLoaded copyWith({bool? isRefreshing}) => AssignedTripsLoaded(
    trips,
    newTripIds: newTripIds,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );
}

class AssignedTripsError extends AssignedTripsState {
  const AssignedTripsError(this.message);

  final String message;
}
