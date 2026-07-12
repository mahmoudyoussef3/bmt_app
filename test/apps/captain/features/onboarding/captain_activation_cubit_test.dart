import 'package:bmt_app/apps/captain/features/auth/domain/exceptions/captain_auth_exceptions.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/repositories/captain_auth_repository.dart';
import 'package:bmt_app/apps/captain/features/auth/domain/usecases/sign_in_captain_usecase.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/cubit/captain_activation_cubit.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/cubit/captain_activation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phone = '01000000000';

  late _FakeAuthRepository repo;
  late CaptainActivationCubit cubit;

  setUp(() {
    repo = _FakeAuthRepository();
    cubit = CaptainActivationCubit(signIn: SignInCaptainUseCase(repo));
  });

  tearDown(() => cubit.close());

  test('waits while operations has not activated the driver yet', () async {
    repo.registered = false;

    await cubit.check(phone);

    expect(cubit.state, isA<CaptainActivationAwaiting>());
  });

  test('a refresh after the driver is activated establishes the session '
      'without signing out', () async {
    repo.registered = false;
    await cubit.check(phone);
    expect(cubit.state, isA<CaptainActivationAwaiting>());

    // Operations activates the driver / assigns a trip.
    repo.registered = true;

    await cubit.check(phone);

    expect(cubit.state, isA<CaptainActivationActivated>());
    expect(repo.signedInPhones, [phone, phone]);
  });

  test('surfaces a failed attempt instead of failing silently', () async {
    repo.error = Exception('تعذّر الاتصال بالخادم');

    await cubit.check(phone);

    expect(cubit.state, isA<CaptainActivationFailed>());
    expect(
      (cubit.state as CaptainActivationFailed).message,
      'تعذّر الاتصال بالخادم',
    );
  });

  test('start checks immediately', () async {
    repo.registered = true;

    cubit.start(phone);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<CaptainActivationActivated>());
  });
}

class _FakeAuthRepository implements CaptainAuthRepository {
  bool registered = true;
  Exception? error;
  final List<String> signedInPhones = [];

  @override
  Future<void> signInWithPhone(String phone) async {
    signedInPhones.add(phone);
    if (error != null) throw error!;
    if (!registered) throw CaptainPhoneNotRegisteredException();
  }

  @override
  Future<void> signOut() async {}
}
