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
      getOffices: GetActiveOfficesUseCase(repo),
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

  test('init loads the active offices into the form', () async {
    repo.offices = const [
      OnboardingOffice(id: 'a', name: 'مكتب أ'),
      OnboardingOffice(id: 'b', name: 'مكتب ب'),
    ];

    cubit.init(null);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as OnboardingForm;
    expect(state.offices, hasLength(2));
    expect(state.requiresOfficeChoice, isTrue);
  });

  test('a single office needs no choice from the applicant', () async {
    repo.offices = const [OnboardingOffice(id: 'a', name: 'المكتب الرئيسي')];

    cubit.init(null);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as OnboardingForm).requiresOfficeChoice, isFalse);
  });

  test('the chosen office and its join code reach the repository', () async {
    repo.submitOutcome = SubmitOutcome.submitted;
    repo.status = null;

    await cubit.submit(
      fullName: 'كابتن',
      phone: '01000000004',
      officeId: 'office-b',
      officeCode: 'K7Q2XM4P',
    );

    expect(repo.lastOfficeId, 'office-b');
    expect(repo.lastOfficeCode, 'K7Q2XM4P');
  });

  test('a rejected code returns to the form with the offices intact', () async {
    repo.offices = const [
      OnboardingOffice(id: 'a', name: 'مكتب أ'),
      OnboardingOffice(id: 'b', name: 'مكتب ب'),
    ];
    cubit.init(null);
    await Future<void>.delayed(Duration.zero);

    repo.failWith = Exception('كود المكتب غير صحيح.');
    await cubit.submit(
      fullName: 'كابتن',
      phone: '01000000005',
      officeId: 'b',
      officeCode: 'WRONG',
    );

    final state = cubit.state as OnboardingForm;
    expect(state.error, 'كود المكتب غير صحيح.');
    expect(state.offices, hasLength(2));
  });
}

class _FakeOnboardingRepository implements CaptainOnboardingRepository {
  SubmitOutcome submitOutcome = SubmitOutcome.submitted;
  CaptainRequestStatusData? status;
  List<OnboardingOffice> offices = const [];

  /// When set, submit throws it — stands in for the server rejecting a bad
  /// office code.
  Object? failWith;

  /// What the last submit carried, so tests can assert the office and code
  /// actually reach the repository.
  String? lastOfficeId;
  String? lastOfficeCode;

  @override
  Future<List<OnboardingOffice>> fetchActiveOffices() async => offices;

  @override
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  }) async {
    lastOfficeId = officeId;
    lastOfficeCode = officeCode;
    if (failWith != null) throw failWith!;
    return SubmitResult(outcome: submitOutcome, phone: phone);
  }

  @override
  Future<CaptainRequestStatusData?> getStatus(String phone) async => status;
}
