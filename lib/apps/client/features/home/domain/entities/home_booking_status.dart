/// Where a rider's booking stands, in the rider's own terms.
///
/// Supabase keeps `operation_bookings.status` in the operational vocabulary
/// `draft | reserved | confirmed | boarded | completed | cancelled`. Only the
/// three below are live commitments the rider still has, so only these reach
/// Home — a draft was never paid for, and a completed or cancelled booking is
/// history rather than something to act on.
enum HomeBookingStatus {
  /// Paid, awaiting the operator's payment review (`reserved`).
  underReview,

  /// Payment approved, the seat is held (`confirmed`).
  confirmed,

  /// The rider is on the bus (`boarded`).
  onBoard;

  /// The `status` values Home queries for.
  static const liveStatuses = <String>['reserved', 'confirmed', 'boarded'];

  /// Reads an `operation_bookings.status`; `null` for a booking Home must not
  /// surface (draft, completed, cancelled, or anything added later).
  static HomeBookingStatus? fromRow(String? status) {
    return switch (status?.trim().toLowerCase()) {
      'reserved' => underReview,
      'confirmed' => confirmed,
      'boarded' => onBoard,
      _ => null,
    };
  }

  String get label => switch (this) {
    underReview => 'Under review',
    confirmed => 'Confirmed',
    onBoard => 'On board',
  };

  /// What the status means for the rider and what happens next, so the badge
  /// never leaves them guessing.
  String get explanation => switch (this) {
    underReview =>
      'We are checking your payment. You will be notified as soon as your '
          'seat is confirmed.',
    confirmed =>
      'Your seat is held. Be at the pickup point 10 minutes before departure.',
    onBoard => 'You are on board. Have a good trip.',
  };

  /// Only a confirmed or boarded rider has a bus worth following.
  bool get isTrackable => this != underReview;
}
