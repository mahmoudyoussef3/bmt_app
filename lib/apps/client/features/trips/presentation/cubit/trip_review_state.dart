import '../../domain/entities/trip_review.dart';
import '../../domain/entities/trip_review_failure.dart';

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
  const TripReviewLoadFailure(this.failure);

  final TripReviewFailure failure;
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

  /// Why the last submit failed, if it did. A reason rather than a sentence —
  /// the widget turns it into localized copy.
  final TripReviewFailure? error;

  /// Stars start unset, so an untouched sheet cannot be submitted as a silent
  /// 5-star review the passenger never actually gave.
  bool get canSubmit => draft.isValid && !isSubmitting;

  /// Standard copy semantics: an omitted field is kept. Clearing [error] is
  /// deliberate rather than incidental — pass [clearError], because silently
  /// dropping the reason on an unrelated copy is how a failure goes missing.
  TripReviewEditing copyWith({
    TripReview? draft,
    bool? isSubmitting,
    TripReviewFailure? error,
    bool clearError = false,
  }) {
    return TripReviewEditing(
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// The review is stored. Shown back to the passenger read-only — reviewing is
/// a one-time act per trip, not a form they keep re-submitting.
class TripReviewSubmitted extends TripReviewState {
  const TripReviewSubmitted(this.review);

  final TripReview review;
}
