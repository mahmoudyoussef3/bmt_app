import '../entities/captain_onboarding_models.dart';

abstract class CaptainOnboardingRepository {
  /// Submits a captain access request (name + phone).
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
  });

  /// Latest review status for a phone, or null if no request exists.
  Future<CaptainRequestStatusData?> getStatus(String phone);
}
