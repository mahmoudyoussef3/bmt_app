import '../../domain/entities/operation_trip.dart';

sealed class TripsState {
  const TripsState();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsError extends TripsState {
  final String message;

  const TripsError(this.message);
}

class TripsLoaded extends TripsState {
  final List<OperationTrip> trips;
  final OperationTrip? selectedTrip;

  const TripsLoaded({required this.trips, this.selectedTrip});

  List<OperationTrip> tripsByStatus(OperationTripStatus status) {
    return trips.where((trip) => trip.status == status).toList();
  }

  TripsLoaded copyWith({
    List<OperationTrip>? trips,
    OperationTrip? selectedTrip,
    bool clearSelectedTrip = false,
  }) {
    return TripsLoaded(
      trips: trips ?? this.trips,
      selectedTrip: clearSelectedTrip
          ? null
          : selectedTrip ?? this.selectedTrip,
    );
  }
}
