import '../entities/captain_onboarding_models.dart';
import '../repositories/captain_onboarding_repository.dart';

class SubmitCaptainRequestUseCase {
  final CaptainOnboardingRepository _repository;
  const SubmitCaptainRequestUseCase(this._repository);

  Future<SubmitResult> call({
    required String fullName,
    required String phone,
  }) => _repository.submit(fullName: fullName, phone: phone);
}

class GetCaptainRequestStatusUseCase {
  final CaptainOnboardingRepository _repository;
  const GetCaptainRequestStatusUseCase(this._repository);

  Future<CaptainRequestStatusData?> call(String phone) =>
      _repository.getStatus(phone);
}
