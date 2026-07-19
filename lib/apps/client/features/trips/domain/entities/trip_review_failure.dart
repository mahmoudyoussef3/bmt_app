/// Why a review could not be read or recorded.
///
/// These mirror the exceptions `submit_trip_review` raises. Naming the reasons
/// here — rather than carrying a sentence — keeps user-facing copy out of the
/// domain and lets presentation say it in the reader's language.
enum TripReviewFailure {
  notAuthenticated,
  bookingNotFound,
  notAuthorized,
  bookingCancelled,
  tripNotCompleted,
  invalidRating,

  /// Anything the backend did not name: a dropped connection, an unmapped
  /// Postgres error, a bug.
  unknown,
}

/// Thrown by the review data and domain layers. Carries a reason, never a
/// message.
class TripReviewException implements Exception {
  const TripReviewException(this.failure, {this.details});

  final TripReviewFailure failure;

  /// The raw underlying error, kept for logs and debugging. Never shown to the
  /// passenger — [failure] is what presentation renders.
  final Object? details;

  @override
  String toString() =>
      'TripReviewException(${failure.name}${details == null ? '' : ', $details'})';
}
