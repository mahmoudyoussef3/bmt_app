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
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}
