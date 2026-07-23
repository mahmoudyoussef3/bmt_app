import 'package:bmt_app/apps/captain/features/auth/domain/exceptions/captain_auth_exceptions.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/repositories/captain_auth_repository.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/repositories/captain_remember_me_repository.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/clear_remembered_phone_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/get_remembered_phone_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/save_remembered_phone_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/sign_in_captain_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/sign_out_captain_usecase.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeCaptainAuthRepository repository;
  late _FakeCaptainRememberMeRepository rememberMeRepository;
  late CaptainAuthCubit cubit;

  setUp(() {
    repository = _FakeCaptainAuthRepository();
    rememberMeRepository = _FakeCaptainRememberMeRepository();
    cubit = CaptainAuthCubit(
      signIn: SignInCaptainUseCase(repository),
      signOut: SignOutCaptainUseCase(repository),
      saveRememberedPhone: SaveRememberedPhoneUseCase(rememberMeRepository),
      getRememberedPhone: GetRememberedPhoneUseCase(rememberMeRepository),
      clearRememberedPhone: ClearRememberedPhoneUseCase(rememberMeRepository),
    );
  });

  tearDown(() => cubit.close());

  test('signs in using the phone number', () async {
    await cubit.signIn(phone: '01285989594', rememberMe: false);

    expect(repository.phone, '01285989594');
    expect(cubit.state, isA<CaptainAuthSuccess>());
  });

  test(
    'emits a not-registered message when the phone has no active driver',
    () async {
      repository.signInError = CaptainPhoneNotRegisteredException();

      await cubit.signIn(phone: '01000000000', rememberMe: false);

      expect(cubit.state, isA<CaptainAuthError>());
      cubit.resetError();
      expect(cubit.state, isA<CaptainAuthIdle>());
    },
  );

  test('emits an error when sign in fails', () async {
    repository.signInError = Exception('بيانات غير صحيحة');

    await cubit.signIn(phone: '01285989594', rememberMe: false);

    expect(cubit.state, isA<CaptainAuthError>());
    cubit.resetError();
    expect(cubit.state, isA<CaptainAuthIdle>());
  });

  test('remembers the phone on request and prefills it back', () async {
    await cubit.signIn(phone: '01285989594', rememberMe: true);

    expect(await cubit.loadRememberedPhone(), '01285989594');
  });

  test('does not remember the phone when the box is unchecked', () async {
    await rememberMeRepository.save('01000000001');

    await cubit.signIn(phone: '01285989594', rememberMe: false);

    expect(await cubit.loadRememberedPhone(), isNull);
  });

  test('signing out lands the captain back at idle', () async {
    await cubit.signIn(phone: '01285989594', rememberMe: false);

    await cubit.signOut();

    expect(repository.signOutCalled, isTrue);
    expect(cubit.state, isA<CaptainAuthIdle>());
  });

  test('a failed sign-out still lands the captain back at idle', () async {
    await cubit.signIn(phone: '01285989594', rememberMe: false);
    repository.signOutError = Exception('network down');

    // Must not throw: the local identity is cleared either way, so stranding
    // the captain on a half-signed-out screen would leave them no action.
    await cubit.signOut();

    expect(cubit.state, isA<CaptainAuthIdle>());
  });

  test('signing out keeps the remembered phone for the next login', () async {
    await cubit.signIn(phone: '01285989594', rememberMe: true);

    await cubit.signOut();

    expect(await cubit.loadRememberedPhone(), '01285989594');
  });
}

class _FakeCaptainRememberMeRepository implements CaptainRememberMeRepository {
  String? _phone;

  @override
  Future<void> save(String phone) async => _phone = phone;

  @override
  Future<String?> read() async => _phone;

  @override
  Future<void> clear() async => _phone = null;
}

class _FakeCaptainAuthRepository implements CaptainAuthRepository {
  String? phone;
  Object? signInError;
  Object? signOutError;
  bool signOutCalled = false;

  @override
  Future<void> signInWithPhone(String phone) async {
    if (signInError case final error?) throw error;
    this.phone = phone;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (signOutError case final error?) throw error;
  }
}
