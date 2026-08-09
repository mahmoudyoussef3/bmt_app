import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_method_failure.dart';
import '../../domain/entities/social_auth_result.dart';
import '../../domain/repositories/social_auth_repository.dart';
import '../datasources/social_auth_datasource.dart';
import '../models/social_auth_result_model.dart';

class SocialAuthRepositoryImpl implements SocialAuthRepository {
  const SocialAuthRepositoryImpl(this._datasource);

  final SocialAuthDatasource _datasource;

  @override
  Future<SocialAuthResult> signInWithGoogle() =>
      _run(AuthMethod.google, _datasource.signInWithGoogle);

  @override
  Future<SocialAuthResult> signInWithApple() =>
      _run(AuthMethod.apple, _datasource.signInWithApple);

  /// Maps the model to an entity and guarantees the one exception type callers
  /// are allowed to see.
  ///
  /// An [AuthMethodException] from the datasource is already classified and
  /// passes straight through; anything else — an SDK's own error type, a
  /// platform channel failure — becomes [AuthMethodFailure.unknown] with the
  /// original text kept for logs only. The cubit therefore never has to guess
  /// what it caught.
  Future<SocialAuthResult> _run(
    AuthMethod method,
    Future<SocialAuthResultModel> Function() call,
  ) async {
    try {
      final model = await call();
      return model.toEntity();
    } on AuthMethodException {
      rethrow;
    } catch (error) {
      throw AuthMethodException(
        AuthMethodFailure.unknown,
        method: method,
        details: error.toString(),
      );
    }
  }
}
