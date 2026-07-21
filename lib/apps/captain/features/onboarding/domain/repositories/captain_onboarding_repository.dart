import '../entities/captain_onboarding_models.dart';

abstract class CaptainOnboardingRepository {
  /// Offices currently accepting applications.
  Future<List<OnboardingOffice>> fetchActiveOffices();

  /// Submits a captain access request. [officeCode] is the code the office
  /// issued the applicant; it is required whenever more than one office is
  /// active, and the server resolves the target office from it.
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  });

  /// Latest review status for a phone, or null if no request exists.
  Future<CaptainRequestStatusData?> getStatus(String phone);
}
