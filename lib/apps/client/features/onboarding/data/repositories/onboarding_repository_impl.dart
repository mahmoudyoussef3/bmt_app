import 'package:bmt_app/apps/client/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _localDataSource;

  OnboardingRepositoryImpl(this._localDataSource);

  @override
  Future<bool> hasSeenOnboarding() async {
    try {
      return await _localDataSource.hasSeenOnboarding();
    } catch (_) {
      return false; // Default to false if error occurs
    }
  }

  @override
  Future<void> completeOnboarding() async {
    await _localDataSource.completeOnboarding();
  }
}
