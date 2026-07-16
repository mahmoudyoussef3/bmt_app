import '../utils/trip_history_filters.dart';

sealed class TripHistoryState {
  const TripHistoryState();
}

class TripHistoryLoading extends TripHistoryState {
  const TripHistoryLoading();
}

/// The history, already filtered and bucketed for display.
///
/// The derived fields are computed by the cubit whenever the trips or the
/// filters change, rather than in `build`: this screen rebuilds on every
/// keystroke of the search field, and re-filtering plus re-grouping the whole
/// history on each of those was the expensive part.
class TripHistoryLoaded extends TripHistoryState {
  const TripHistoryLoaded({
    required this.totalTrips,
    required this.totalPassengers,
    required this.groups,
    required this.query,
    required this.dateFilter,
  });

  /// Counts across the whole history, before filtering — the headline
  /// "N رحلة مكتملة" and the summary tiles must not move when the captain
  /// narrows the view.
  final int totalTrips;
  final int totalPassengers;

  /// The filtered trips, bucketed by recency. Empty when nothing matches.
  final List<TripHistoryGroup> groups;

  final String query;
  final TripHistoryDateFilter dateFilter;

  /// No completed trips at all, as opposed to none matching the current
  /// filters — the two read differently to a captain.
  bool get hasNoTrips => totalTrips == 0;

  bool get hasNoMatches => groups.isEmpty;
}

class TripHistoryError extends TripHistoryState {
  const TripHistoryError(this.message);
  final String message;
}
