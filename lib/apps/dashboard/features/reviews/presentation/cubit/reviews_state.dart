import '../../domain/entities/reviews_summary.dart';
import '../../domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

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
  });

  /// Every review, unfiltered — the summary is always computed over all of
  /// them, so narrowing the list never moves the averages.
  final List<TripReviewEntry> reviews;
  final ReviewsFilter filter;
  final String query;

  /// True when the query came back full at [DashboardQueryCaps.reviews]. The
  /// averages below are computed over [reviews], so when this is true they
  /// describe the newest slice and not the driver's whole record.
  bool get capReached => reviews.length >= DashboardQueryCaps.reviews;

  ReviewsSummary get summary => ReviewsSummary.from(reviews);

  List<DriverRatingStanding> get driverStandings =>
      DriverRatingStanding.rank(reviews);

  List<TripReviewEntry> get visibleReviews {
    return reviews.where((review) {
      final passesFilter = switch (filter) {
        ReviewsFilter.all => true,
        ReviewsFilter.needsAttention => review.needsAttention,
        ReviewsFilter.withComments => review.hasComment,
      };
      return passesFilter && review.matches(query);
    }).toList();
  }

  bool get isEmpty => reviews.isEmpty;

  /// Distinguishes "nobody has reviewed anything yet" from "your filter hid
  /// everything" — the two need different empty states.
  bool get isFilteredEmpty => reviews.isNotEmpty && visibleReviews.isEmpty;

  ReviewsLoaded copyWith({
    List<TripReviewEntry>? reviews,
    ReviewsFilter? filter,
    String? query,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
}
