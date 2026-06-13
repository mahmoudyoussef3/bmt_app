abstract class ClientAuthDatasource {
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
}
