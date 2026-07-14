import '../../domain/entities/trip.dart';

sealed class TripsState {
  const TripsState();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsLoaded extends TripsState {
  const TripsLoaded({
    required this.trips,
    this.selectedTrip,
    this.cancelInFlight = false,
    this.cancelFailure,
    this.cancelledReference,
  });

  final List<TripData> trips;
  final TripData? selectedTrip;

  /// A cancellation is being written to Supabase. The screen stays readable —
  /// only the cancel action itself is blocked.
  final bool cancelInFlight;

  /// The outcome of the last cancellation, carried for exactly one emit so a
  /// rebuild never replays the same snackbar.
  final String? cancelFailure;
  final String? cancelledReference;

  TripsLoaded copyWith({
    List<TripData>? trips,
    TripData? selectedTrip,
    bool? cancelInFlight,
    String? cancelFailure,
    String? cancelledReference,
  }) {
    return TripsLoaded(
      trips: trips ?? this.trips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      cancelInFlight: cancelInFlight ?? this.cancelInFlight,
      cancelFailure: cancelFailure,
      cancelledReference: cancelledReference,
    );
  }
}

class TripsError extends TripsState {
  const TripsError(this.message);

  final String message;
}
