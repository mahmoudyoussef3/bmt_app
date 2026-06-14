import 'package:bmt_app/core/security/secure_storage.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasSeenOnboarding();
  Future<void> completeOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final SecureStorage _secureStorage;
  static const _key = 'has_seen_onboarding';

  OnboardingLocalDataSourceImpl(this._secureStorage);

  @override
  Future<bool> hasSeenOnboarding() async {
    final result = await _secureStorage.read(_key);
    return result == 'true';
  }

  @override
  Future<void> completeOnboarding() async {
    await _secureStorage.write(_key, 'true');
  }
}
