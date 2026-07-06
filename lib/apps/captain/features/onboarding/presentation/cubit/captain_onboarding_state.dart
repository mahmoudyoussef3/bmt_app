sealed class CaptainOnboardingState {
  const CaptainOnboardingState();
}

/// Showing the name + phone request form. [error] is a non-fatal submit error.
class OnboardingForm extends CaptainOnboardingState {
  final String? error;
  const OnboardingForm({this.error});
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
