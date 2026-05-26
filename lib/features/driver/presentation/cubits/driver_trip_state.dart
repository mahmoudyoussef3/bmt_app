part of 'driver_trip_cubit.dart';

class DriverTripState {
  final List<Trip> assignedTrips;
  final bool isLoading;

  const DriverTripState({
    this.assignedTrips = const [],
    this.isLoading = false,
  });

  DriverTripState copyWith({List<Trip>? assignedTrips, bool? isLoading}) {
    return DriverTripState(
      assignedTrips: assignedTrips ?? this.assignedTrips,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
