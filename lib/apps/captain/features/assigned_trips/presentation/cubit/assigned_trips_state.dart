import '../../domain/entities/assigned_trip.dart';

sealed class AssignedTripsState {
  const AssignedTripsState();
}

class AssignedTripsLoading extends AssignedTripsState {
  const AssignedTripsLoading();
}

class AssignedTripsLoaded extends AssignedTripsState {
  const AssignedTripsLoaded(this.trips);

  final List<AssignedTrip> trips;
}

class AssignedTripsError extends AssignedTripsState {
  const AssignedTripsError(this.message);

  final String message;
}
