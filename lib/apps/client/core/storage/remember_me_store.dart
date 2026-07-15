import 'package:bmt_app/core/security/secure_storage.dart';

/// Encrypted-at-rest cache for the "Remember Me" email/password pair.
///
/// Passwords must never sit in `SharedPreferences` (plaintext, backed up
/// unencrypted on some Android OEMs); Keychain/Keystore via [SecureStorage]
/// is the minimum bar for this project.
class RememberMeStore {
  RememberMeStore({SecureStorage? storage}) : _storage = storage ?? SecureStorage();

  final SecureStorage _storage;

  static const _emailKey = 'client_remember_me_email';
  static const _passwordKey = 'client_remember_me_password';

  Future<void> save({required String email, required String password}) async {
    await _storage.write(_emailKey, email);
    await _storage.write(_passwordKey, password);
  }

  /// Returns `(email, password)`, or null if nothing — or only half a pair —
  /// is stored. A partial read (e.g. one key evicted by the OS) must not
  /// silently prefill an empty password field.
  Future<(String, String)?> read() async {
    try {
      final email = await _storage.read(_emailKey);
      final password = await _storage.read(_passwordKey);
      if (email == null || password == null) return null;
      return (email, password);
    } catch (_) {
      // A corrupted keystore entry must degrade to "nothing remembered",
      // never crash the login screen.
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(_emailKey);
    await _storage.delete(_passwordKey);
  }
}
