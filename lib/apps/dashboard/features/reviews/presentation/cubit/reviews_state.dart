import '../../domain/entities/reviews_summary.dart';
import '../../domain/entities/trip_review_entry.dart';
import '../models/review_sort.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

/// How many reviews one page of the feed holds — the same number الشكاوى next
/// door pages by, so the الدعم section does not read as two consoles.
const int reviewsPageSize = 12;

/// How operations slices the feed. `needsAttention` is the one that matters on
/// a busy day: it is the unhappy-passenger queue.
enum ReviewsFilter { all, needsAttention, withComments }

extension ReviewsFilterLabel on ReviewsFilter {
  String get label => switch (this) {
    ReviewsFilter.all => 'كل التقييمات',
    ReviewsFilter.needsAttention => 'تحتاج متابعة',
    ReviewsFilter.withComments => 'بها تعليقات',
  };
}

sealed class ReviewsState {
  const ReviewsState();
}

class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

class ReviewsError extends ReviewsState {
  const ReviewsError(this.message);

  final String message;
}

class ReviewsLoaded extends ReviewsState {
  const ReviewsLoaded({
    required this.reviews,
    this.filter = ReviewsFilter.all,
    this.query = '',
    this.band = ReviewRatingBand.any,
    this.driverName,
    this.routeLabel,
    this.sort = ReviewSort.createdAt,
    this.sortAscending = false,
  });

  /// Every review, unfiltered — the summary is always computed over all of
  /// them, so narrowing the list never moves the averages.
  final List<TripReviewEntry> reviews;
  final ReviewsFilter filter;
  final String query;

  /// The star band, the captain and the corridor: the three narrowings that sit
  /// behind the toolbar's «التصفية» fold, beside the queue strip that owns
  /// [filter].
  final ReviewRatingBand band;
  final String? driverName;
  final String? routeLabel;

  final ReviewSort sort;

  /// Newest first by default: a review the office has not seen yet is the one
  /// worth opening the module for.
  final bool sortAscending;

  /// True when the query came back full at [DashboardQueryCaps.reviews]. The
  /// averages below are computed over [reviews], so when this is true they
  /// describe the newest slice and not the driver's whole record.
  bool get capReached => reviews.length >= DashboardQueryCaps.reviews;

  ReviewsSummary get summary => ReviewsSummary.from(reviews);

  List<DriverRatingStanding> get driverStandings =>
      DriverRatingStanding.rank(reviews);

  /// Every captain the loaded feed mentions, for the filter dropdown. Derived
  /// rather than declared: a captain with no reviews is not a choice worth
  /// offering on a screen that only shows reviews.
  List<String> get driverNames => _namesOf((review) => review.driverName);

  List<String> get routeLabels => _namesOf((review) => review.routeLabel);

  List<String> _namesOf(String Function(TripReviewEntry) pick) {
    final seen = <String>{};
    for (final review in reviews) {
      final value = pick(review).trim();
      if (value.isNotEmpty) seen.add(value);
    }
    final sorted = seen.toList()..sort();
    return sorted;
  }

  List<TripReviewEntry> get visibleReviews {
    final matching = reviews.where((review) {
      final passesFilter = switch (filter) {
        ReviewsFilter.all => true,
        ReviewsFilter.needsAttention => review.needsAttention,
        ReviewsFilter.withComments => review.hasComment,
      };
      if (!passesFilter) return false;
      if (!band.matches(review.averageRating)) return false;
      if (driverName != null && review.driverName != driverName) return false;
      if (routeLabel != null && review.routeLabel != routeLabel) return false;
      return review.matches(query);
    }).toList();

    int compare(TripReviewEntry a, TripReviewEntry b) => switch (sort) {
      ReviewSort.createdAt => a.createdAt.compareTo(b.createdAt),
      ReviewSort.rating => a.averageRating.compareTo(b.averageRating),
      ReviewSort.driver => a.driverName.compareTo(b.driverName),
    };

    matching.sort((a, b) {
      final result = compare(a, b);
      return sortAscending ? result : -result;
    });
    return matching;
  }

  /// Drives the reset button's badge. The sort is not a filter — it changes the
  /// order, not the population — so it is not counted here.
  int get activeFilterCount => [
    query.trim().isNotEmpty,
    filter != ReviewsFilter.all,
    band != ReviewRatingBand.any,
    driverName != null,
    routeLabel != null,
  ].where((active) => active).length;

  bool get isFiltered => activeFilterCount > 0;

  bool get isEmpty => reviews.isEmpty;

  /// Distinguishes "nobody has reviewed anything yet" from "your filter hid
  /// everything" — the two need different empty states.
  bool get isFilteredEmpty => reviews.isNotEmpty && visibleReviews.isEmpty;

  ReviewsLoaded copyWith({
    List<TripReviewEntry>? reviews,
    ReviewsFilter? filter,
    String? query,
    ReviewRatingBand? band,
    String? driverName,
    String? routeLabel,
    ReviewSort? sort,
    bool? sortAscending,
    bool clearDriverName = false,
    bool clearRouteLabel = false,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      band: band ?? this.band,
      driverName: clearDriverName ? null : (driverName ?? this.driverName),
      routeLabel: clearRouteLabel ? null : (routeLabel ?? this.routeLabel),
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
