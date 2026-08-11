abstract class CaptainRememberMeRepository {
  Future<void> save(String phone);

  Future<String?> read();

  Future<void> clear();
}
