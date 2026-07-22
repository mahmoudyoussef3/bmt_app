import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/office_onboarding.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/repositories/platform_admin_repository.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/usecases/platform_admin_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late PlatformAdminCubit cubit;

  PlatformOffice office({
    String id = 'office-a',
    String name = 'مكتب الإسكندرية',
    String status = 'active',
    String listingStatus = 'draft',
    String description = 'نقل يومي',
    List<String> serviceAreas = const ['الإسكندرية'],
  }) => PlatformOffice(
    id: id,
    name: name,
    slug: 'alex-office',
    description: description,
    serviceAreas: serviceAreas,
    status: status,
    listingStatus: listingStatus,
    rating: 0,
    ratingsCount: 0,
    operators: 1,
    drivers: 0,
    routes: 0,
  );

  const validRequest = OfficeOnboardingRequest(
    name: 'مكتب الإسكندرية',
    adminUsername: 'ops.alex',
    slug: 'alex-office',
  );

  setUp(() {
    repo = _FakeRepo()..offices = [office()];
    cubit = PlatformAdminCubit(
      getOffices: GetPlatformOfficesUseCase(repo),
      onboardOffice: OnboardOfficeUseCase(repo),
      setListing: SetOfficeListingUseCase(repo),
      setStatus: SetOfficeStatusUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('exposes the platform office list', () async {
      await cubit.load();

      final state = cubit.state;
      expect(state, isA<PlatformAdminLoaded>());
      expect((state as PlatformAdminLoaded).offices, hasLength(1));
      expect(state.draftCount, 1);
      expect(state.listedCount, 0);
    });

    test('surfaces a read failure as an error state', () async {
      repo.failRead = true;

      await cubit.load();

      expect(cubit.state, isA<PlatformAdminError>());
    });
  });

  group('onboard', () {
    test('reveals the credentials once on success', () async {
      await cubit.load();
      repo.result = const OfficeOnboardingResult(
        officeId: 'office-b',
        officeName: 'مكتب الإسكندرية',
        slug: 'alex-office',
        joinCode: 'ABCD2345',
        username: 'ops.alex',
        listingStatus: 'draft',
        temporaryPassword: 'Str0ng!Passw0rd',
      );
      repo.offices = [office(), office(id: 'office-b')];

      await cubit.onboard(validRequest);

      final state = cubit.state;
      expect(state, isA<PlatformAdminOnboarded>());
      final onboarded = state as PlatformAdminOnboarded;
      expect(onboarded.result.temporaryPassword, 'Str0ng!Passw0rd');
      expect(onboarded.result.joinCode, 'ABCD2345');
      // The list behind the reveal already contains the new office, so
      // dismissing lands on a current list rather than a stale one.
      expect(onboarded.offices, hasLength(2));
    });

    test('a rejected request never reaches the repository', () async {
      await cubit.load();

      await cubit.onboard(
        const OfficeOnboardingRequest(name: 'مك', adminUsername: 'x'),
      );

      expect(repo.onboardCalls, 0);
      final state = cubit.state;
      expect(state, isA<PlatformAdminLoaded>());
      expect((state as PlatformAdminLoaded).fieldErrors, isNotEmpty);
      expect(state.fieldErrors.keys, containsAll(['name', 'adminUsername']));
    });

    test('a server failure keeps the list on screen', () async {
      await cubit.load();
      repo.failWrite = true;

      await cubit.onboard(validRequest);

      final state = cubit.state;
      expect(state, isA<PlatformAdminLoaded>());
      expect((state as PlatformAdminLoaded).offices, hasLength(1));
      expect(state.isSubmitting, isFalse);
    });

    test('still reveals the credentials when the reload fails', () async {
      // The password exists in exactly one place — this response. A failed
      // refresh must not be allowed to discard it.
      await cubit.load();
      repo.result = const OfficeOnboardingResult(
        officeId: 'office-b',
        officeName: 'مكتب',
        slug: 'alex-office',
        joinCode: 'ABCD2345',
        username: 'ops.alex',
        listingStatus: 'draft',
        temporaryPassword: 'Str0ng!Passw0rd',
      );
      repo.failRead = true;

      await cubit.onboard(validRequest);

      expect(cubit.state, isA<PlatformAdminOnboarded>());
    });

    test('dismissing the reveal returns to the list', () async {
      await cubit.load();
      repo.result = const OfficeOnboardingResult(
        officeId: 'office-b',
        officeName: 'مكتب',
        slug: 'alex-office',
        joinCode: 'ABCD2345',
        username: 'ops.alex',
        listingStatus: 'draft',
      );

      await cubit.onboard(validRequest);
      cubit.dismissOnboardingResult();

      expect(cubit.state, isA<PlatformAdminLoaded>());
    });
  });

  group('listing', () {
    test('publishing reloads and announces', () async {
      await cubit.load();
      repo.offices = [office(listingStatus: 'listed')];

      await cubit.setListing('office-a', 'listed');

      expect(repo.listingCalls, [('office-a', 'listed')]);
      final state = cubit.state;
      expect(state, isA<PlatformAdminLoaded>());
      expect((state as PlatformAdminLoaded).listedCount, 1);
    });

    test('rejects a listing status the database would refuse', () async {
      await cubit.load();

      await cubit.setListing('office-a', 'published');

      expect(repo.listingCalls, isEmpty);
    });

    test('a refused publish keeps the previous list', () async {
      await cubit.load();
      repo.failWrite = true;

      await cubit.setListing('office-a', 'listed');

      final state = cubit.state;
      expect(state, isA<PlatformAdminLoaded>());
      expect((state as PlatformAdminLoaded).offices.single.isListed, isFalse);
    });
  });

  group('status', () {
    test('suspending reloads and announces', () async {
      await cubit.load();
      repo.offices = [office(status: 'suspended')];

      await cubit.setStatus('office-a', 'suspended');

      expect(repo.statusCalls, [('office-a', 'suspended')]);
      expect(cubit.state, isA<PlatformAdminLoaded>());
    });

    test('rejects a status the database would refuse', () async {
      await cubit.load();

      await cubit.setStatus('office-a', 'deleted');

      expect(repo.statusCalls, isEmpty);
    });
  });

  group('PlatformOffice', () {
    test('is listed only when active AND listed', () {
      expect(office(status: 'active', listingStatus: 'listed').isListed, isTrue);
      expect(
        office(status: 'paused', listingStatus: 'listed').isListed,
        isFalse,
      );
      expect(
        office(status: 'active', listingStatus: 'draft').isListed,
        isFalse,
      );
    });

    test('names what blocks publishing, mirroring the RPC guard', () {
      expect(office().blockersToListing, isEmpty);
      expect(
        office(description: '  ').blockersToListing,
        contains('وصف المكتب مفقود'),
      );
      expect(
        office(serviceAreas: const []).blockersToListing,
        contains('لم تُحدَّد مناطق الخدمة'),
      );
      expect(
        office(status: 'suspended').blockersToListing,
        contains('المكتب غير نشط'),
      );
    });
  });
}

class _FakeRepo implements PlatformAdminRepository {
  List<PlatformOffice> offices = const [];
  OfficeOnboardingResult? result;
  bool failRead = false;
  bool failWrite = false;

  int onboardCalls = 0;
  final List<(String, String)> listingCalls = [];
  final List<(String, String)> statusCalls = [];

  @override
  Future<List<PlatformOffice>> getOffices() async {
    if (failRead) throw Exception('read failed');
    return offices;
  }

  @override
  Future<OfficeOnboardingResult> onboardOffice(
    OfficeOnboardingRequest request,
  ) async {
    onboardCalls++;
    if (failWrite) throw Exception('write failed');
    return result!;
  }

  @override
  Future<void> setListingStatus(String officeId, String listingStatus) async {
    if (failWrite) throw Exception('write failed');
    listingCalls.add((officeId, listingStatus));
  }

  @override
  Future<void> setOfficeStatus(String officeId, String status) async {
    if (failWrite) throw Exception('write failed');
    statusCalls.add((officeId, status));
  }
}
