import '../../domain/entities/remembered_credentials.dart';
import '../../domain/usecases/clear_remembered_credentials_usecase.dart';
import '../../domain/usecases/get_remembered_credentials_usecase.dart';
import '../../domain/usecases/save_remembered_credentials_usecase.dart';

/// Coordinates the "Remember Me" credential cache for [ClientAuthCubit], keeping
/// device-storage side effects out of the authentication flow itself.
class RememberMeCoordinator {
  const RememberMeCoordinator({
    required SaveRememberedCredentialsUseCase save,
    required GetRememberedCredentialsUseCase get,
    required ClearRememberedCredentialsUseCase clear,
  }) : _save = save,
       _get = get,
       _clear = clear;

  final SaveRememberedCredentialsUseCase _save;
  final GetRememberedCredentialsUseCase _get;
  final ClearRememberedCredentialsUseCase _clear;

  /// Reads previously saved credentials. A read failure (e.g. a corrupted
  /// keystore entry) renders as "nothing remembered" rather than an error, so
  /// it never blocks the login screen from opening.
  Future<RememberedCredentials?> load() async {
    try {
      return await _get();
    } catch (_) {
      return null;
    }
  }

  /// Persists or clears the remembered pair. A write failure must never turn a
  /// successful sign-in into a reported failure, so it is swallowed.
  Future<void> apply(
    bool rememberMe, {
    required String email,
    required String password,
  }) async {
    try {
      if (rememberMe) {
        await _save(email: email, password: password);
      } else {
        await _clear();
      }
    } catch (_) {}
  }
}
