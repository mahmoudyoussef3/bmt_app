import '../entities/client_profile.dart';

abstract class ProfileRepository {
  Future<ClientProfile> getProfile();

  /// Persists the rider's contact details and returns the stored profile, so
  /// callers render what the backend actually kept rather than what was typed.
  Future<ClientProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  });
}
