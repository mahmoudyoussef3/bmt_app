import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';

sealed class PlatformAdminState {
  const PlatformAdminState();
}

class PlatformAdminInitial extends PlatformAdminState {
  const PlatformAdminInitial();
}

class PlatformAdminLoading extends PlatformAdminState {
  const PlatformAdminLoading();
}

/// The screen has no data — a failed load, not a failed action.
class PlatformAdminError extends PlatformAdminState {
  const PlatformAdminError(this.message);
  final String message;
}

class PlatformAdminLoaded extends PlatformAdminState {
  const PlatformAdminLoaded(
    this.offices, {
    this.isSubmitting = false,
    this.fieldErrors = const {},
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;

  /// Per-field validation errors from the last rejected submission, keyed the
  /// way [OfficeOnboardingRequest.validate] keys them, so the form can mark the
  /// offending input rather than show one message with no anchor.
  final Map<String, String> fieldErrors;

  int get listedCount => offices.where((o) => o.isListed).length;
  int get draftCount => offices.where((o) => o.isDraft).length;

  PlatformAdminLoaded copyWith({
    List<PlatformOffice>? offices,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
  }) => PlatformAdminLoaded(
    offices ?? this.offices,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
}

/// An office was onboarded. Carries the one-time reveal: the generated password
/// and the join code, neither of which can be read back from anywhere.
///
/// A distinct state rather than a flag on [PlatformAdminLoaded] because the
/// screen has to *hold* this until the operator dismisses it — losing it to a
/// rebuild would lose the only copy of the password.
class PlatformAdminOnboarded extends PlatformAdminState {
  const PlatformAdminOnboarded(this.result, this.offices);
  final OfficeOnboardingResult result;
  final List<PlatformOffice> offices;
}

/// A one-frame success notice for the smaller actions (publish / withdraw /
/// suspend), immediately followed by [PlatformAdminLoaded] — the same shape the
/// office_profile and referrals modules use, so listeners behave identically.
class PlatformAdminActionSuccess extends PlatformAdminState {
  const PlatformAdminActionSuccess(this.message, this.offices);
  final String message;
  final List<PlatformOffice> offices;
}

/// A failed action that keeps the list — and whatever is typed into the form —
/// on screen.
class PlatformAdminActionFailure extends PlatformAdminState {
  const PlatformAdminActionFailure(
    this.message,
    this.offices, {
    this.fieldErrors = const {},
  });
  final String message;
  final List<PlatformOffice> offices;
  final Map<String, String> fieldErrors;
}
