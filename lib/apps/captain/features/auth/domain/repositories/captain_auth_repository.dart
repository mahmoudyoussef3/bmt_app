abstract class CaptainAuthRepository {
  /// Throws [CaptainPhoneNotRegisteredException] when [phone] has no
  /// matching active driver.
  Future<void> signInWithPhone(String phone);

  Future<void> signOut();
}
