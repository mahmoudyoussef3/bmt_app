/// How the review feed is ordered.
///
/// Lives here rather than in [ReviewsTable]'s private state so the toolbar's
/// pinned [DashboardSortControl] and the sortable column headers drive one
/// value — while the table owned it, the feed could only be re-ordered by
/// finding the right column header, and nothing on screen said what order it
/// was in.
enum ReviewSort {
  createdAt('التاريخ'),
  rating('التقييم'),
  driver('السائق');

  const ReviewSort(this.label);

  final String label;
}

/// The star band a review falls in, by its three-dimension average.
///
/// Bands rather than an exact star count: a review averaging 4.3 is a
/// four-star review to everyone reading this screen, and offering "٤٫٣٣ فقط"
/// as a filter would return one row.
enum ReviewRatingBand {
  any('كل التقييمات', null),
  five('٥ نجوم', 5),
  four('٤ نجوم', 4),
  three('٣ نجوم', 3),
  two('نجمتان', 2),
  one('نجمة واحدة', 1);

  const ReviewRatingBand(this.label, this.stars);

  final String label;

  /// The rounded average this band holds, or null for "no band".
  final int? stars;

  bool matches(double average) => stars == null || average.round() == stars;
}
