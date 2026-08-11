import '../utils/trip_history_filters.dart';

sealed class TripHistoryState {
  const TripHistoryState();
}

class TripHistoryLoading extends TripHistoryState {
  const TripHistoryLoading();
}

class TripHistoryLoaded extends TripHistoryState {
  const TripHistoryLoaded({
    required this.totalTrips,
    required this.totalPassengers,
    required this.groups,
    required this.matchCount,
    required this.filterCounts,
    required this.query,
    required this.dateFilter,
  });

  final int totalTrips;
  final int totalPassengers;

  final List<TripHistoryGroup> groups;

  final int matchCount;

  final Map<TripHistoryDateFilter, int> filterCounts;

  final String query;
  final TripHistoryDateFilter dateFilter;

  bool get hasNoTrips => totalTrips == 0;

  bool get hasNoMatches => groups.isEmpty;

  bool get isFiltering =>
      query.trim().isNotEmpty || dateFilter != TripHistoryDateFilter.all;

  int get averagePassengers =>
      totalTrips == 0 ? 0 : (totalPassengers / totalTrips).round();
}

class TripHistoryError extends TripHistoryState {
  const TripHistoryError(this.message);
  final String message;
}
