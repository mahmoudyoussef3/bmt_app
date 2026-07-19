import '../../domain/entities/trip_review_failure.dart';

/// Translates the bare exception names `submit_trip_review` raises into
/// [TripReviewFailure]. Backend-string knowledge lives here in the data layer
/// so the domain enum stays pure Dart — the same split as `TripStatusMapper`.
///
/// The RPC raises these as plain Postgres exceptions, so the name arrives
/// embedded in a longer message rather than as a code.
abstract final class TripReviewFailureMapper {
  static TripReviewFailure fromMessage(String raw) {
    if (raw.contains('trip_not_completed')) {
      return TripReviewFailure.tripNotCompleted;
    }
    if (raw.contains('booking_cancelled')) {
      return TripReviewFailure.bookingCancelled;
    }
    if (raw.contains('not_authorized')) {
      return TripReviewFailure.notAuthorized;
    }
    if (raw.contains('booking_not_found')) {
      return TripReviewFailure.bookingNotFound;
    }
    if (raw.contains('invalid_rating')) {
      return TripReviewFailure.invalidRating;
    }
    if (raw.contains('not_authenticated')) {
      return TripReviewFailure.notAuthenticated;
    }
    return TripReviewFailure.unknown;
  }
}
