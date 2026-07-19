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
    this.filter = TripFilter.upcoming,
    this.selectedTrip,
    this.cancelInFlight = false,
    this.cancelFailure,
    this.cancelledReference,
  });

  final List<TripData> trips;

  /// The filter tab currently selected on the My Trips list.
  final TripFilter filter;

  final TripData? selectedTrip;

  /// A cancellation is being written to Supabase. The screen stays readable —
  /// only the cancel action itself is blocked.
  final bool cancelInFlight;

  /// The outcome of the last cancellation, carried for exactly one emit so a
  /// rebuild never replays the same snackbar.
  final String? cancelFailure;
  final String? cancelledReference;

  /// Trips matching the currently selected filter tab.
  List<TripData> get filteredTrips =>
      trips.where((trip) => trip.status == filter.statusMatch).toList();

  /// How many trips sit under each filter tab.
  Map<TripFilter, int> get counts => {
    for (final f in TripFilter.values)
      f: trips.where((trip) => trip.status == f.statusMatch).length,
  };

  /// The next state after a re-read: re-resolves the selected trip against the
  /// new list and keeps the current filter tab.
  TripsLoaded withTrips(List<TripData> trips, {String? cancelledReference}) {
    final selectedId = selectedTrip?.id;
    return TripsLoaded(
      trips: trips,
      filter: filter,
      selectedTrip: trips.where((t) => t.id == selectedId).firstOrNull,
      cancelledReference: cancelledReference,
    );
  }

  TripsLoaded copyWith({
    List<TripData>? trips,
    TripFilter? filter,
    TripData? selectedTrip,
    bool? cancelInFlight,
    String? cancelFailure,
    String? cancelledReference,
  }) {
    return TripsLoaded(
      trips: trips ?? this.trips,
      filter: filter ?? this.filter,
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
