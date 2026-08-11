import '../../domain/entities/captain_onboarding_models.dart';

sealed class CaptainOnboardingState {
  const CaptainOnboardingState();
}

class OnboardingForm extends CaptainOnboardingState {
  final String? error;
  final List<OnboardingOffice> offices;
  final bool loadingOffices;

  const OnboardingForm({
    this.error,
    this.offices = const [],
    this.loadingOffices = false,
  });

  bool get requiresOfficeChoice => offices.length > 1;
}

class OnboardingSubmitting extends CaptainOnboardingState {
  const OnboardingSubmitting();
}

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

class OnboardingAlreadyActive extends CaptainOnboardingState {
  const OnboardingAlreadyActive();
}
