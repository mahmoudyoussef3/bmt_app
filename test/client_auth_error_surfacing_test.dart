import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/auth/data/datasources/client_auth_datasource.dart';
import 'package:bmt_app/apps/client/features/auth/data/repositories/client_auth_repository_impl.dart';
import 'package:bmt_app/apps/client/features/auth/domain/entities/remembered_credentials.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/remember_me_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/clear_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/get_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/save_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/remember_me_coordinator.dart';

class _FakeRememberMeRepository implements RememberMeRepository {
  @override
  Future<void> save({required String email, required String password}) async {}

  @override
  Future<RememberedCredentials?> read() async => null;

  @override
  Future<void> clear() async {}
}

/// Fake datasource that throws whatever it is configured to throw, so we can
/// assert the exact message the user ends up seeing.
class _FakeDatasource implements ClientAuthDatasource {
  _FakeDatasource({this.onSignUp, this.onSignIn});

  final Object? Function()? onSignUp;
  final Object? Function()? onSignIn;

  @override
  Future<void> signUpWithEmail({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final error = onSignUp?.call();
    if (error != null) throw error;
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final error = onSignIn?.call();
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}

ClientAuthCubit buildCubit(ClientAuthDatasource ds) {
  final repo = ClientAuthRepositoryImpl(ds);
  final rememberMeRepo = _FakeRememberMeRepository();
  return ClientAuthCubit(
    signInWithEmail: SignInWithEmailUseCase(repo),
    signUpWithEmail: SignUpWithEmailUseCase(repo),
    signOut: SignOutUseCase(repo),
    rememberMe: RememberMeCoordinator(
      save: SaveRememberedCredentialsUseCase(rememberMeRepo),
      get: GetRememberedCredentialsUseCase(rememberMeRepo),
      clear: ClearRememberedCredentialsUseCase(rememberMeRepo),
    ),
  );
}

void main() {
  group('auth error surfacing (regression: masked messages)', () {
    test(
      'duplicate-phone message reaches the user verbatim, not masked',
      () async {
        const message =
            'This phone number is already registered.\n'
            'Please sign in instead, or use a different number.';
        final cubit = buildCubit(
          _FakeDatasource(onSignUp: () => Exception(message)),
        );

        await cubit.signUp(
          fullName: 'Jane',
          phone: '+201000000000',
          email: 'jane@example.com',
          password: 'secret123',
        );

        expect(cubit.state.signUpStatus, AuthSubmissionStatus.failure);
        // The actionable reason must survive — never collapsed into a generic
        // "Unable to create account" / "Sign up failed: ..." wrapper.
        expect(cubit.state.signUpError, message);
        expect(cubit.state.signUpError, isNot(contains('Sign up failed')));
      },
    );

    test(
      'sign-in failure surfaces the real reason, not a blanket message',
      () async {
        final cubit = buildCubit(
          _FakeDatasource(
            onSignIn: () => Exception('Invalid login credentials'),
          ),
        );

        await cubit.signIn(
          email: 'jane@example.com',
          password: 'wrong',
          rememberMe: false,
        );

        expect(cubit.state.signInStatus, AuthSubmissionStatus.failure);
        expect(cubit.state.signInError, 'Invalid login credentials');
        expect(cubit.state.signInError, isNot(contains('Sign in failed')));
      },
    );

    test(
      'validation FormatException is preserved through the layers',
      () async {
        final cubit = buildCubit(
          _FakeDatasource(
            onSignUp: () =>
                const FormatException('Please complete all fields.'),
          ),
        );

        await cubit.signUp(
          fullName: 'J',
          phone: '',
          email: 'bad',
          password: '123',
        );

        expect(cubit.state.signUpStatus, AuthSubmissionStatus.failure);
        expect(cubit.state.signUpError, 'Please complete all fields.');
      },
    );
  });
}
