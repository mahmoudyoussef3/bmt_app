import '../../domain/entities/trip_review.dart';

sealed class TripReviewState {
  const TripReviewState();
}

/// Checking whether this trip has already been reviewed.
class TripReviewLoading extends TripReviewState {
  const TripReviewLoading();
}

/// The review could not be loaded — the passenger is offered a retry rather
/// than a blank sheet that might silently overwrite an existing review.
class TripReviewLoadFailure extends TripReviewState {
  const TripReviewLoadFailure(this.message);

  final String message;
}

/// The passenger is filling in (or amending) their review.
class TripReviewEditing extends TripReviewState {
  const TripReviewEditing({
    required this.draft,
    this.isSubmitting = false,
    this.error,
  });

  final TripReview draft;
  final bool isSubmitting;
  final String? error;

  /// Stars start unset, so an untouched sheet cannot be submitted as a silent
  /// 5-star review the passenger never actually gave.
  bool get canSubmit => draft.isValid && !isSubmitting;

  TripReviewEditing copyWith({
    TripReview? draft,
    bool? isSubmitting,
    String? error,
  }) {
    return TripReviewEditing(
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

/// The review is stored. Shown back to the passenger read-only — reviewing is
/// a one-time act per trip, not a form they keep re-submitting.
class TripReviewSubmitted extends TripReviewState {
  const TripReviewSubmitted(this.review);

  final TripReview review;
}
