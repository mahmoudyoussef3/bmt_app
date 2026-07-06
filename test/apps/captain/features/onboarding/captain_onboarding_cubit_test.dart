import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/features/onboarding/domain/entities/captain_onboarding_models.dart';
import 'package:bmt_app/apps/captain/features/onboarding/domain/repositories/captain_onboarding_repository.dart';
import 'package:bmt_app/apps/captain/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/cubit/captain_onboarding_cubit.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/cubit/captain_onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOnboardingRepository repo;
  late CaptainSessionStore store;
  late CaptainOnboardingCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakeOnboardingRepository();
    store = CaptainSessionStore();
    cubit = CaptainOnboardingCubit(
      submit: SubmitCaptainRequestUseCase(repo),
      getStatus: GetCaptainRequestStatusUseCase(repo),
      store: store,
    );
  });

  tearDown(() => cubit.close());

  test('an active phone routes straight to sign in', () async {
    repo.submitOutcome = SubmitOutcome.alreadyActive;

    await cubit.submit(fullName: 'كابتن نشط', phone: '01000000000');

    expect(cubit.state, isA<OnboardingAlreadyActive>());
  });

  test('a new request goes pending and persists the phone', () async {
    repo.submitOutcome = SubmitOutcome.submitted;
    repo.status = const CaptainRequestStatusData(
      status: RequestStatus.pending,
      fullName: 'كابتن جديد',
      phone: '201000000001',
    );

    await cubit.submit(fullName: 'كابتن جديد', phone: '01000000001');

    expect(cubit.state, isA<OnboardingPending>());
    expect(await store.readPendingPhone(), isNotNull);
  });

  test('approval establishes a local session', () async {
    repo.submitOutcome = SubmitOutcome.submitted;
    repo.status = const CaptainRequestStatusData(
      status: RequestStatus.pending,
      fullName: 'كابتن',
      phone: '201000000002',
    );
    await cubit.submit(fullName: 'كابتن', phone: '01000000002');

    repo.status = const CaptainRequestStatusData(
      status: RequestStatus.approved,
      fullName: 'كابتن',
      phone: '201000000002',
      driverId: 'driver-1',
      employeeCode: 'EMP-100',
    );
    await cubit.refreshNow();

    expect(cubit.state, isA<OnboardingApproved>());

    final session = await cubit.establishSession(
      cubit.state as OnboardingApproved,
    );
    expect(session.driverId, 'driver-1');
    expect((await store.readSession())?.driverId, 'driver-1');
    // Saving a session clears the pending marker.
    expect(await store.readPendingPhone(), isNull);
  });

  test('rejection surfaces the operations reason', () async {
    repo.submitOutcome = SubmitOutcome.submitted;
    repo.status = const CaptainRequestStatusData(
      status: RequestStatus.rejected,
      fullName: 'كابتن',
      phone: '201000000003',
      rejectionReason: 'المستندات غير مكتملة',
    );

    await cubit.submit(fullName: 'كابتن', phone: '01000000003');
    await cubit.refreshNow();

    expect(cubit.state, isA<OnboardingRejected>());
    expect((cubit.state as OnboardingRejected).reason, 'المستندات غير مكتملة');
  });
}

class _FakeOnboardingRepository implements CaptainOnboardingRepository {
  SubmitOutcome submitOutcome = SubmitOutcome.submitted;
  CaptainRequestStatusData? status;

  @override
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
  }) async {
    return SubmitResult(outcome: submitOutcome, phone: phone);
  }

  @override
  Future<CaptainRequestStatusData?> getStatus(String phone) async => status;
}
