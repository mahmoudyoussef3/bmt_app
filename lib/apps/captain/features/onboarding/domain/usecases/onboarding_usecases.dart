import '../entities/captain_onboarding_models.dart';
import '../repositories/captain_onboarding_repository.dart';

class SubmitCaptainRequestUseCase {
  final CaptainOnboardingRepository _repository;
  const SubmitCaptainRequestUseCase(this._repository);

  Future<SubmitResult> call({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  }) => _repository.submit(
    fullName: fullName,
    phone: phone,
    officeId: officeId,
    officeCode: officeCode,
  );
}

class GetActiveOfficesUseCase {
  final CaptainOnboardingRepository _repository;
  const GetActiveOfficesUseCase(this._repository);

  Future<List<OnboardingOffice>> call() => _repository.fetchActiveOffices();
}

class GetCaptainRequestStatusUseCase {
  final CaptainOnboardingRepository _repository;
  const GetCaptainRequestStatusUseCase(this._repository);

  Future<CaptainRequestStatusData?> call(String phone) =>
      _repository.getStatus(phone);
}
