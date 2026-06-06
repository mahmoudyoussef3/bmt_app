import '../../domain/entities/trip.dart';

sealed class TripsState {
  const TripsState();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsLoaded extends TripsState {
  const TripsLoaded({required this.trips, this.selectedTrip});

  final List<TripData> trips;
  final TripData? selectedTrip;
}

class TripsError extends TripsState {
  const TripsError(this.message);

  final String message;
}
