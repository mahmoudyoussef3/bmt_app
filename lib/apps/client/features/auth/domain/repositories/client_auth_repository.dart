abstract class ClientAuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  /// Sets a new password on the session Supabase established from the
  /// recovery link (see [sendPasswordResetEmail]'s emailed redirect).
  Future<void> updatePassword(String newPassword);
}
