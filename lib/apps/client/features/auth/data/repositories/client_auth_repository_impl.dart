import '../../domain/repositories/client_auth_repository.dart';
import '../datasources/client_auth_datasource.dart';

class ClientAuthRepositoryImpl implements ClientAuthRepository {
  const ClientAuthRepositoryImpl(this._datasource);

  final ClientAuthDatasource _datasource;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _datasource.signInWithEmail(email: email, password: password);
    } on FormatException {
      rethrow;
    } on Exception {
      // The datasource already maps failures to clear, user-facing messages;
      // rethrow as-is instead of masking them behind a generic prefix.
      rethrow;
    } catch (error) {
      throw Exception('Sign in failed. Please try again.');
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      await _datasource.signUpWithEmail(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        referralCode: referralCode,
      );
    } on FormatException {
      rethrow;
    } on Exception {
      // Preserve the datasource's actionable message (duplicate phone/email,
      // etc.) instead of collapsing it into a generic prefix.
      rethrow;
    } catch (error) {
      throw Exception('Sign up failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    await _datasource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
    } on FormatException {
      rethrow;
    } catch (error) {
      if (error.toString().contains('RateLimit')) {
        throw Exception('RateLimit');
      }
      throw Exception('Failed to send reset email: $error');
    }
  }
}
