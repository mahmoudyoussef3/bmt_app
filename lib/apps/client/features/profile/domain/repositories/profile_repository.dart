import '../entities/client_profile.dart';

/// Thrown when a call requires a signed-in rider but the current session has
/// none (guest mode). Kept distinct from other failures so the presentation
/// layer can offer a sign-in prompt instead of a dead-end "try again".
class ProfileUnauthenticatedException implements Exception {
  const ProfileUnauthenticatedException();
}

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
