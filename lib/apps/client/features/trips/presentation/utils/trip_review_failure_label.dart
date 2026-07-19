import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/trip_review_failure.dart';

/// Turns a review failure into copy in the reader's language.
///
/// This is the only place a [TripReviewFailure] becomes a sentence — the data
/// and domain layers name the reason and say nothing about how it reads.
String tripReviewFailureLabel(BuildContext context, TripReviewFailure failure) {
  final l10n = context.l10n;
  return switch (failure) {
    TripReviewFailure.notAuthenticated => l10n.trips_reviewErrorSignIn,
    TripReviewFailure.bookingNotFound => l10n.trips_reviewErrorBookingMissing,
    TripReviewFailure.notAuthorized => l10n.trips_reviewErrorNotYourTrip,
    TripReviewFailure.bookingCancelled => l10n.trips_reviewErrorCancelled,
    TripReviewFailure.tripNotCompleted => l10n.trips_reviewErrorNotCompleted,
    TripReviewFailure.invalidRating => l10n.trips_reviewErrorInvalidRating,
    TripReviewFailure.unknown => l10n.trips_reviewErrorUnknown,
  };
}
