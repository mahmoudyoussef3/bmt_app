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

class _FakeRememberMeRepository implements RememberMeRepository {
  @override
  Future<void> save({required String email, required String password}) async {}

  @override
  Future<RememberedCredentials?> read() async => null;

  @override
  Future<void> clear() async {}
}

class _FakeAuthRepository implements ClientAuthRepository {
  _FakeAuthRepository({this.signOutFails = false});

  final bool signOutFails;
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutFails) throw Exception('network down');
  }

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
  Future<void> sendPasswordResetEmail(String email) async {}
}

ClientAuthCubit _cubit(_FakeAuthRepository repository) {
  final rememberMeRepo = _FakeRememberMeRepository();
  return ClientAuthCubit(
    signInWithEmail: SignInWithEmailUseCase(repository),
    signUpWithEmail: SignUpWithEmailUseCase(repository),
    signOut: SignOutUseCase(repository),
    saveRememberedCredentials: SaveRememberedCredentialsUseCase(rememberMeRepo),
    getRememberedCredentials: GetRememberedCredentialsUseCase(rememberMeRepo),
    clearRememberedCredentials: ClearRememberedCredentialsUseCase(
      rememberMeRepo,
    ),
  );
}

void main() {
  group('ClientAuthCubit.signOut', () {
    // The profile screen only resets the navigation stack on `success`. If the
    // cubit stayed silent — as it used to — the rider would tap "Log out" and
    // stay exactly where they were.
    test(
      'reports success so the UI can leave the authenticated stack',
      () async {
        final repository = _FakeAuthRepository();
        final cubit = _cubit(repository);

        final emitted = <AuthSubmissionStatus>[];
        final subscription = cubit.stream.listen(
          (state) => emitted.add(state.signOutStatus),
        );
        await cubit.signOut();
        // Bloc delivers to listeners asynchronously, so the queue has to drain
        // before the emissions can be asserted on.
        await pumpEventQueue();
        await subscription.cancel();

        expect(repository.signOutCalls, 1);
        expect(emitted, [
          AuthSubmissionStatus.loading,
          AuthSubmissionStatus.success,
        ]);
      },
    );

    test(
      'reports failure instead of silently leaving the rider signed in',
      () async {
        final cubit = _cubit(_FakeAuthRepository(signOutFails: true));

        await cubit.signOut();

        expect(cubit.state.signOutStatus, AuthSubmissionStatus.failure);
        expect(cubit.state.signOutError, isNotNull);
      },
    );

    test('a second tap while signing out does not sign out twice', () async {
      final repository = _FakeAuthRepository();
      final cubit = _cubit(repository);

      final first = cubit.signOut();
      await cubit.signOut();
      await first;

      expect(repository.signOutCalls, 1);
    });

    test('signing out does not disturb the sign-in form state', () async {
      final cubit = _cubit(_FakeAuthRepository());

      await cubit.signOut();

      expect(cubit.state.signInStatus, AuthSubmissionStatus.initial);
      expect(cubit.state.signInError, isNull);
    });
  });
}
