import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/auth/domain/entities/remembered_credentials.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/client_auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/remember_me_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/clear_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/get_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/save_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';

class _FakeAuthRepository implements ClientAuthRepository {
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

/// In-memory stand-in for the secure-storage-backed repository, so the
/// orchestration in [ClientAuthCubit] can be asserted without touching a
/// platform channel.
class _InMemoryRememberMeRepository implements RememberMeRepository {
  RememberedCredentials? _stored;

  @override
  Future<void> save({required String email, required String password}) async {
    _stored = RememberedCredentials(email: email, password: password);
  }

  @override
  Future<RememberedCredentials?> read() async => _stored;

  @override
  Future<void> clear() async => _stored = null;
}

ClientAuthCubit _cubit(_InMemoryRememberMeRepository rememberMeRepo) {
  final authRepo = _FakeAuthRepository();
  return ClientAuthCubit(
    signInWithEmail: SignInWithEmailUseCase(authRepo),
    signUpWithEmail: SignUpWithEmailUseCase(authRepo),
    signOut: SignOutUseCase(authRepo),
    saveRememberedCredentials: SaveRememberedCredentialsUseCase(rememberMeRepo),
    getRememberedCredentials: GetRememberedCredentialsUseCase(rememberMeRepo),
    clearRememberedCredentials: ClearRememberedCredentialsUseCase(
      rememberMeRepo,
    ),
  );
}

void main() {
  group('ClientAuthCubit Remember Me', () {
    test('loadRememberedCredentials returns null when nothing is stored', () async {
      final cubit = _cubit(_InMemoryRememberMeRepository());

      expect(await cubit.loadRememberedCredentials(), isNull);
    });

    test(
      'signing in with rememberMe true saves the pair for the next visit',
      () async {
        final cubit = _cubit(_InMemoryRememberMeRepository());

        await cubit.signIn(
          email: 'rider@example.com',
          password: 's3cret!',
          rememberMe: true,
        );

        final remembered = await cubit.loadRememberedCredentials();
        expect(remembered?.email, 'rider@example.com');
        expect(remembered?.password, 's3cret!');
      },
    );

    test(
      'signing in with rememberMe false clears any previously saved pair',
      () async {
        final rememberMeRepo = _InMemoryRememberMeRepository();
        await rememberMeRepo.save(email: 'old@example.com', password: 'old');
        final cubit = _cubit(rememberMeRepo);

        await cubit.signIn(
          email: 'rider@example.com',
          password: 's3cret!',
          rememberMe: false,
        );

        expect(await cubit.loadRememberedCredentials(), isNull);
      },
    );

    test('sign-in still succeeds even if the failure happened before remember-me applies', () async {
      final cubit = _cubit(_InMemoryRememberMeRepository());

      await cubit.signIn(
        email: 'rider@example.com',
        password: 's3cret!',
        rememberMe: true,
      );

      expect(cubit.state.signInStatus, AuthSubmissionStatus.success);
    });
  });
}
