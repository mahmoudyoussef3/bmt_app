import 'package:bmt_app/apps/captain/features/auth/domain/repositories/captain_auth_repository.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/sign_in_captain_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/sign_out_captain_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeCaptainAuthRepository repository;
  late CaptainAuthCubit cubit;

  setUp(() {
    repository = _FakeCaptainAuthRepository();
    cubit = CaptainAuthCubit(
      signIn: SignInCaptainUseCase(repository),
      signOut: SignOutCaptainUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('signs in using email and password', () async {
    await cubit.signIn(
      email: 'captain.emp1@bmt-app.com',
      password: 'test-password',
    );

    expect(repository.email, 'captain.emp1@bmt-app.com');
    expect(repository.password, 'test-password');
    expect(cubit.state, isA<CaptainAuthSuccess>());
  });

  test('emits an error when sign in fails', () async {
    repository.signInError = Exception('بيانات غير صحيحة');

    await cubit.signIn(email: 'captain@example.com', password: 'wrong');

    expect(cubit.state, isA<CaptainAuthError>());
    cubit.resetError();
    expect(cubit.state, isA<CaptainAuthIdle>());
  });
}

class _FakeCaptainAuthRepository implements CaptainAuthRepository {
  String? email;
  String? password;
  Object? signInError;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError case final error?) throw error;
    this.email = email;
    this.password = password;
  }

  @override
  Future<void> signOut() async {}
}
