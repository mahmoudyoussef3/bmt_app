import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_details.dart';
import '../../domain/entities/platform_office_filter.dart';

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
    this.filter = const PlatformOfficeFilter(),
    this.selection,
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;

  /// Per-field validation errors from the last rejected submission, keyed the
  /// way [OfficeOnboardingRequest.validate] keys them, so the form can mark the
  /// offending input rather than show one message with no anchor.
  final Map<String, String> fieldErrors;

  final PlatformOfficeFilter filter;

  /// The office whose details panel is open, if any.
  final PlatformOfficeSelection? selection;

  /// What the list should actually render. The unfiltered [offices] stays intact
  /// beside it so the summary counts keep describing the platform rather than
  /// the current search — a header that changed with every keystroke would stop
  /// being a platform overview.
  List<PlatformOffice> get visibleOffices => filter.apply(offices);

  int get listedCount => offices.where((o) => o.isListed).length;
  int get draftCount => offices.where((o) => o.isDraft).length;

  /// Offices that are active but not on the marketplace — the triage queue this
  /// screen exists for.
  int get awaitingListingCount => offices
      .where((o) => o.status == 'active' && o.listingStatus != 'listed')
      .length;

  PlatformAdminLoaded copyWith({
    List<PlatformOffice>? offices,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    PlatformOfficeFilter? filter,
    PlatformOfficeSelection? selection,
    bool clearSelection = false,
  }) => PlatformAdminLoaded(
    offices ?? this.offices,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    filter: filter ?? this.filter,
    selection: clearSelection ? null : (selection ?? this.selection),
  );
}

/// The open details panel: which office, and how far its details have got.
///
/// [officeId] is held separately from [details] so the panel can show the right
/// office's name while its detail is still loading, and so a failed load is
/// attributable to an office rather than floating free of one.
class PlatformOfficeSelection {
  const PlatformOfficeSelection({
    required this.officeId,
    this.details,
    this.isLoading = false,
    this.error,
  });

  final String officeId;
  final PlatformOfficeDetails? details;
  final bool isLoading;
  final String? error;

  PlatformOfficeSelection copyWith({
    String? officeId,
    PlatformOfficeDetails? details,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => PlatformOfficeSelection(
    officeId: officeId ?? this.officeId,
    details: details ?? this.details,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
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
