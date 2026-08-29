import '../cubit/reviews_state.dart';

/// The queues التقييمات is worked through, as the strip الشكاوى, الحجوزات,
/// الاشتراكات and العملاء all open with.
///
/// The slices themselves are not new — [ReviewsFilter] has always had these
/// three — but they used to render as bare [ChoiceChip]s with a count baked
/// into one label. As [DashboardQueueTab]s they carry their own count, tint the
/// unhappy-passenger queue as outstanding work, and look like every other queue
/// strip in the console.
extension ReviewQueueTab on ReviewsFilter {
  /// The tab's own count, over the *whole* feed rather than the current view —
  /// a tab that counted only what is already on screen would always read as the
  /// number of rows below it.
  int countIn(ReviewsLoaded state) => switch (this) {
    ReviewsFilter.all => state.summary.total,
    ReviewsFilter.needsAttention => state.summary.needsAttentionCount,
    ReviewsFilter.withComments => state.summary.commentedCount,
  };

  /// The unhappy-passenger queue is outstanding work: while it holds rows and
  /// is not the open tab, its badge says so from across the room.
  bool get isWorkQueue => this == ReviewsFilter.needsAttention;
}
