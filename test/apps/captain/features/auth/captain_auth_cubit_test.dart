import 'package:bmt_app/apps/captain/features/auth/domain/exceptions/captain_auth_exceptions.dart';
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

  test('signs in using the phone number', () async {
    await cubit.signIn(phone: '01285989594');

    expect(repository.phone, '01285989594');
    expect(cubit.state, isA<CaptainAuthSuccess>());
  });

  test(
    'emits a not-registered message when the phone has no active driver',
    () async {
      repository.signInError = CaptainPhoneNotRegisteredException();

      await cubit.signIn(phone: '01000000000');

      expect(cubit.state, isA<CaptainAuthError>());
      cubit.resetError();
      expect(cubit.state, isA<CaptainAuthIdle>());
    },
  );

  test('emits an error when sign in fails', () async {
    repository.signInError = Exception('بيانات غير صحيحة');

    await cubit.signIn(phone: '01285989594');

    expect(cubit.state, isA<CaptainAuthError>());
    cubit.resetError();
    expect(cubit.state, isA<CaptainAuthIdle>());
  });
}

class _FakeCaptainAuthRepository implements CaptainAuthRepository {
  String? phone;
  Object? signInError;

  @override
  Future<void> signInWithPhone(String phone) async {
    if (signInError case final error?) throw error;
    this.phone = phone;
  }

  @override
  Future<void> signOut() async {}
}
