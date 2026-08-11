import '../entities/captain_onboarding_models.dart';

abstract class CaptainOnboardingRepository {
  Future<List<OnboardingOffice>> fetchActiveOffices();

  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  });

  Future<CaptainRequestStatusData?> getStatus(String phone);
}
