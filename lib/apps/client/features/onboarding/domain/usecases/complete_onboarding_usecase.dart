import 'package:bmt_app/apps/client/features/onboarding/domain/repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase {
  final OnboardingRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  Future<void> call() async {
    await _repository.completeOnboarding();
  }
}
