/// Local-only "Remember Me" cache, independent of the actual auth session.
/// Signing out must not touch this — the whole point is that the phone
/// number is still there to prefill the next time the login screen opens.
abstract class CaptainRememberMeRepository {
  Future<void> save(String phone);

  Future<String?> read();

  Future<void> clear();
}
