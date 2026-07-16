import '../../domain/entities/assigned_trip.dart';

sealed class AssignedTripsState {
  const AssignedTripsState();
}

class AssignedTripsLoading extends AssignedTripsState {
  const AssignedTripsLoading();
}

class AssignedTripsLoaded extends AssignedTripsState {
  const AssignedTripsLoaded(this.trips, {this.newTripIds = const {}});

  final List<AssignedTrip> trips;

  /// Trips assigned since the captain last acknowledged the home screen's
  /// "new assignment" notice — a purely local, device-side notion (see
  /// [SeenTripsRepository]), not a backend field.
  final Set<String> newTripIds;
}

class AssignedTripsError extends AssignedTripsState {
  const AssignedTripsError(this.message);

  final String message;
}
