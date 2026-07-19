import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/data/mappers/trip_review_failure_mapper.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review_failure.dart';

/// `submit_trip_review` raises these as bare Postgres exceptions, so the name
/// reaches the client wrapped in a longer message. These are the exact strings
/// the migration raises — if the RPC renames one, this is what catches it,
/// because the passenger would otherwise silently fall through to a generic
/// "could not submit" for a reason we know how to explain.
void main() {
  group('TripReviewFailureMapper', () {
    const raised = <String, TripReviewFailure>{
      'not_authenticated': TripReviewFailure.notAuthenticated,
      'booking_not_found': TripReviewFailure.bookingNotFound,
      'not_authorized': TripReviewFailure.notAuthorized,
      'booking_cancelled': TripReviewFailure.bookingCancelled,
      'trip_not_completed': TripReviewFailure.tripNotCompleted,
      'invalid_rating': TripReviewFailure.invalidRating,
    };

    test('maps every reason the RPC raises', () {
      for (final entry in raised.entries) {
        expect(
          TripReviewFailureMapper.fromMessage(entry.key),
          entry.value,
          reason: 'bare "${entry.key}" should map to ${entry.value.name}',
        );
      }
    });

    test('finds the reason inside a wrapped Postgres message', () {
      expect(
        TripReviewFailureMapper.fromMessage(
          'PostgrestException(message: trip_not_completed, code: P0001)',
        ),
        TripReviewFailure.tripNotCompleted,
      );
    });

    test('falls back to unknown rather than guessing', () {
      expect(
        TripReviewFailureMapper.fromMessage('connection closed'),
        TripReviewFailure.unknown,
      );
      expect(
        TripReviewFailureMapper.fromMessage(''),
        TripReviewFailure.unknown,
      );
    });

    test('does not confuse booking_not_found with not_authorized', () {
      // Both contain "not_", and an earlier draft ordered these checks so that
      // one shadowed the other.
      expect(
        TripReviewFailureMapper.fromMessage('booking_not_found'),
        TripReviewFailure.bookingNotFound,
      );
      expect(
        TripReviewFailureMapper.fromMessage('not_authorized'),
        TripReviewFailure.notAuthorized,
      );
    });
  });
}
