import '../entities/remembered_credentials.dart';

/// Local-only "Remember Me" cache, independent of the actual auth session.
/// Signing out must not touch this — the whole point is that the email and
/// password are still there to prefill the next time the login screen opens.
abstract class RememberMeRepository {
  Future<void> save({required String email, required String password});

  Future<RememberedCredentials?> read();

  Future<void> clear();
}
