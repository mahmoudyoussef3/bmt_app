import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/search_options.dart';

enum SearchOptionsStatus { loading, loaded, error }

/// Holds the trip-search form: the in-progress query, the async pickup/
/// destination/time options, and per-field recent-search shortcuts.
class BookingSearchState {
  const BookingSearchState({
    this.query = const BookingSearchQuery(),
    this.options,
    this.optionsStatus = SearchOptionsStatus.loading,
    this.optionsError,
    this.recentPickups = const [],
    this.recentDestinations = const [],
  });

  final BookingSearchQuery query;
  final TripSearchOptions? options;
  final SearchOptionsStatus optionsStatus;
  final String? optionsError;
  final List<String> recentPickups;
  final List<String> recentDestinations;

  bool get optionsLoading => optionsStatus == SearchOptionsStatus.loading;
  List<String> get pickupOptions => options?.pickupPoints ?? const [];
  List<String> get destinationOptions => options?.destinations ?? const [];
  List<String> get timeOptions => options?.departureTimes ?? const [];

  BookingSearchState copyWith({
    BookingSearchQuery? query,
    TripSearchOptions? options,
    SearchOptionsStatus? optionsStatus,
    String? optionsError,
    bool clearOptionsError = false,
    List<String>? recentPickups,
    List<String>? recentDestinations,
  }) {
    return BookingSearchState(
      query: query ?? this.query,
      options: options ?? this.options,
      optionsStatus: optionsStatus ?? this.optionsStatus,
      optionsError: clearOptionsError
          ? null
          : optionsError ?? this.optionsError,
      recentPickups: recentPickups ?? this.recentPickups,
      recentDestinations: recentDestinations ?? this.recentDestinations,
    );
  }
}
