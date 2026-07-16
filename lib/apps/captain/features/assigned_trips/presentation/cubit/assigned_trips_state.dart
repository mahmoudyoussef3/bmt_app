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

  /// Trips assigned since the captain last acknowledged the home screen's
  /// "new assignment" notice — a purely local, device-side notion (see
  /// [SeenTripsRepository]), not a backend field.
  final Set<String> newTripIds;

  /// A captain-initiated refresh is in flight.
  ///
  /// Only ever true for an explicit refresh, never for the realtime-triggered
  /// background poll: the empty-state view turns this into a visible spinner
  /// and a "جاري التحديث…" label, and that should answer the captain's tap
  /// rather than flicker on its own whenever operations touches the schedule.
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
