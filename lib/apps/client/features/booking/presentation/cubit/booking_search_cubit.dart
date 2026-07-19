import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/storage/recent_search_store.dart';

import '../../domain/entities/booking_search_query.dart';
import '../../domain/usecases/get_search_options_usecase.dart';
import 'booking_search_state.dart';

/// Owns the trip-search form state: the in-progress [BookingSearchQuery], the
/// async search options, and the per-field recent-search shortcuts.
class BookingSearchCubit extends Cubit<BookingSearchState> {
  BookingSearchCubit(this._getSearchOptions)
    : super(const BookingSearchState());

  final GetSearchOptionsUseCase _getSearchOptions;
  final RecentSearchStore _recentStore = const RecentSearchStore();
  bool _optionsInFlight = false;

  /// Seeds the query (route args + today's date label) and kicks off the
  /// options + recent-search loads. Call once when the screen mounts.
  void init(BookingSearchQuery initial, {required String todayDate}) {
    final query = initial.date.isEmpty
        ? initial.copyWith(date: todayDate)
        : initial;
    emit(state.copyWith(query: query));
    loadOptions();
    _loadRecents();
  }

  Future<void> loadOptions() async {
    if (_optionsInFlight) return;
    _optionsInFlight = true;
    emit(
      state.copyWith(
        optionsStatus: SearchOptionsStatus.loading,
        clearOptionsError: true,
      ),
    );
    try {
      final options = await _getSearchOptions();
      emit(
        state.copyWith(
          options: options,
          optionsStatus: SearchOptionsStatus.loaded,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          optionsStatus: SearchOptionsStatus.error,
          optionsError: error.toString(),
        ),
      );
    } finally {
      _optionsInFlight = false;
    }
  }

  Future<void> selectPickup(String value) async {
    emit(state.copyWith(query: state.query.copyWith(pickup: value)));
    await _recordRecent(RecentSearchStore.pickupsKey, value, isPickup: true);
  }

  Future<void> selectDestination(String value) async {
    emit(state.copyWith(query: state.query.copyWith(destination: value)));
    await _recordRecent(
      RecentSearchStore.destinationsKey,
      value,
      isPickup: false,
    );
  }

  void setDate(String value) =>
      emit(state.copyWith(query: state.query.copyWith(date: value)));

  void setTime(String value) =>
      emit(state.copyWith(query: state.query.copyWith(time: value)));

  void swap() {
    final q = state.query;
    emit(
      state.copyWith(
        query: q.copyWith(pickup: q.destination, destination: q.pickup),
      ),
    );
  }

  Future<void> _loadRecents() async {
    final pickups = await _recentStore.get(RecentSearchStore.pickupsKey);
    final destinations = await _recentStore.get(
      RecentSearchStore.destinationsKey,
    );
    emit(
      state.copyWith(recentPickups: pickups, recentDestinations: destinations),
    );
  }

  Future<void> _recordRecent(
    String key,
    String value, {
    required bool isPickup,
  }) async {
    await _recentStore.add(key, value);
    final current = isPickup ? state.recentPickups : state.recentDestinations;
    final updated = [
      value,
      ...current.where((r) => r != value),
    ].take(5).toList();
    emit(
      isPickup
          ? state.copyWith(recentPickups: updated)
          : state.copyWith(recentDestinations: updated),
    );
  }
}
