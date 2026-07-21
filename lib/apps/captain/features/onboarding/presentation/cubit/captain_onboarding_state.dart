import '../../domain/entities/captain_onboarding_models.dart';

sealed class CaptainOnboardingState {
  const CaptainOnboardingState();
}

/// Showing the request form. [error] is a non-fatal submit error.
///
/// [offices] drives the picker. When more than one office is active the
/// applicant must choose one and enter that office's join code — the server
/// refuses an uncoded request in that case, so the picker is not a
/// convenience, it is how the request becomes valid at all.
class OnboardingForm extends CaptainOnboardingState {
  final String? error;
  final List<OnboardingOffice> offices;
  final bool loadingOffices;

  const OnboardingForm({
    this.error,
    this.offices = const [],
    this.loadingOffices = false,
  });

  /// A single active office needs neither a picker nor a code.
  bool get requiresOfficeChoice => offices.length > 1;
}

class OnboardingSubmitting extends CaptainOnboardingState {
  const OnboardingSubmitting();
}

/// Request queued; polling for a review decision.
class OnboardingPending extends CaptainOnboardingState {
  final String phone;
  const OnboardingPending(this.phone);
}

class OnboardingApproved extends CaptainOnboardingState {
  final String name;
  final String phone;
  final String driverId;
  final String employeeCode;
  const OnboardingApproved({
    required this.name,
    required this.phone,
    required this.driverId,
    required this.employeeCode,
  });
}

class OnboardingRejected extends CaptainOnboardingState {
  final String reason;
  const OnboardingRejected(this.reason);
}

/// The phone already belongs to an active captain — send them to sign in.
class OnboardingAlreadyActive extends CaptainOnboardingState {
  const OnboardingAlreadyActive();
}
