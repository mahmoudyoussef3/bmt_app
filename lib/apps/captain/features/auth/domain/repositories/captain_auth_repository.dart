abstract class CaptainAuthRepository {
  Future<void> signInWithPhone(String phone);

  Future<void> signOut();
}
