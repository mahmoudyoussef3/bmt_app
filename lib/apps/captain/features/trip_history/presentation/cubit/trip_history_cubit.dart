import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_history_item.dart';
import '../../domain/usecases/get_trip_history_usecase.dart';
import '../utils/trip_history_filters.dart';
import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  TripHistoryCubit(this._getHistory) : super(const TripHistoryLoading());

  final GetTripHistoryUseCase _getHistory;

  /// The unfiltered history. Kept here so re-filtering never needs a re-fetch,
  /// and so the summary counts stay whole-history while the list narrows.
  List<TripHistoryItem> _allTrips = const [];

  /// The live filters. They live on the cubit rather than the screen so that
  /// a refresh — or a rebuild of the tab — can't silently drop the captain's
  /// search back to "الكل".
  String _query = '';
  TripHistoryDateFilter _dateFilter = TripHistoryDateFilter.all;

  Future<void> load() async {
    emit(const TripHistoryLoading());
    try {
      final trips = await _getHistory();
      if (isClosed) return;
      _allTrips = trips;
      _emitLoaded();
    } catch (e) {
      if (isClosed) return;
      emit(TripHistoryError(e.toString()));
    }
  }

  /// Re-fetches quietly, keeping the current list on screen — a pull-to-
  /// refresh that flashed back to the loading skeleton every time would be a
  /// jarring way to check for one new completed trip. Falls back to [load]
  /// only when there's nothing loaded yet to refresh.
  Future<void> refresh() async {
    if (state is! TripHistoryLoaded) return load();
    try {
      final trips = await _getHistory();
      if (isClosed) return;
      _allTrips = trips;
      _emitLoaded();
    } catch (_) {
      // Keep showing the current list on a silent refresh failure.
    }
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    _emitLoaded();
  }

  void filterByDate(TripHistoryDateFilter filter) {
    if (filter == _dateFilter) return;
    _dateFilter = filter;
    _emitLoaded();
  }

  /// Drops the captain back to the whole history in one step.
  ///
  /// The search field owns its own text, so it clears that itself before
  /// calling this — the query is never pushed back down into the field.
  void clearFilters() {
    if (_query.isEmpty && _dateFilter == TripHistoryDateFilter.all) return;
    _query = '';
    _dateFilter = TripHistoryDateFilter.all;
    _emitLoaded();
  }

  void _emitLoaded() {
    final filtered = filterTripHistory(
      trips: _allTrips,
      dateFilter: _dateFilter,
      query: _query,
    );
    emit(
      TripHistoryLoaded(
        totalTrips: _allTrips.length,
        totalPassengers: _allTrips.fold(0, (sum, t) => sum + t.boardedCount),
        groups: groupTripHistoryByPeriod(filtered),
        matchCount: filtered.length,
        filterCounts: countTripsByDateFilter(_allTrips),
        query: _query,
        dateFilter: _dateFilter,
      ),
    );
  }
}
