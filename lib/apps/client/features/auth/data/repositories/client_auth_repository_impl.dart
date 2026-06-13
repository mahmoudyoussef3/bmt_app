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
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      await _datasource.signUpWithEmail(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  @override
  Future<void> signOut() async {
    await _datasource.signOut();
  }
}
