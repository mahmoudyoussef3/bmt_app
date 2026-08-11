import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_history_item.dart';
import '../../domain/usecases/get_trip_history_usecase.dart';
import '../utils/trip_history_filters.dart';
import 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  TripHistoryCubit(this._getHistory) : super(const TripHistoryLoading());

  final GetTripHistoryUseCase _getHistory;

  List<TripHistoryItem> _allTrips = const [];

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

  Future<void> refresh() async {
    if (state is! TripHistoryLoaded) return load();
    try {
      final trips = await _getHistory();
      if (isClosed) return;
      _allTrips = trips;
      _emitLoaded();
    } catch (_) {}
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
