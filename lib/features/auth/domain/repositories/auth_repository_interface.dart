abstract class IAuthRepository {
  /// Attempts login and returns a token string on success.
  Future<String> login(String username, String password);

  /// Invalidates current session/token.
  Future<void> logout(String token);

  /// Optional token validation.
  Future<bool> validateToken(String token);
}
