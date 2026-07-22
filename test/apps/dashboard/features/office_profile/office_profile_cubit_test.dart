import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/repositories/office_profile_repository.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/usecases/office_profile_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/cubit/office_profile_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late OfficeProfileCubit cubit;

  OfficeProfile profile({
    String name = 'مكتب القاهرة',
    String description = 'نقل يومي بين القاهرة والجيزة',
    String? logoUrl = 'https://cdn.example.com/logo.png',
    List<String> serviceAreas = const ['القاهرة'],
    String status = 'active',
    String listingStatus = 'listed',
  }) => OfficeProfile(
    id: 'office-1',
    name: name,
    slug: 'cairo-office',
    description: description,
    serviceAreas: serviceAreas,
    status: status,
    listingStatus: listingStatus,
    rating: 4.5,
    ratingsCount: 12,
    joinCode: 'ABCD2345',
    logoUrl: logoUrl,
    phone: '0100000000',
  );

  setUp(() {
    repo = _FakeRepo()..profile = profile();
    cubit = OfficeProfileCubit(
      getProfile: GetOfficeProfileUseCase(repo),
      updateProfile: UpdateOfficeProfileUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  test('load exposes the office row', () async {
    await cubit.load();

    final state = cubit.state;
    expect(state, isA<OfficeProfileLoaded>());
    expect((state as OfficeProfileLoaded).profile.joinCode, 'ABCD2345');
  });

  group('marketplace visibility reads listing_status, not status', () {
    test('an active office that is still a draft is not listed', () {
      final draft = profile(status: 'active', listingStatus: 'draft');

      // The regression this guards: `isListed => status == 'active'` reported
      // every freshly onboarded office as visible to passengers.
      expect(draft.isListed, isFalse);
      expect(draft.isDraft, isTrue);
      expect(draft.listingLabel, 'قيد التجهيز');
      expect(draft.statusLabel, 'نشط');
    });

    test('a listed active office is on the marketplace', () {
      final listed = profile(status: 'active', listingStatus: 'listed');

      expect(listed.isListed, isTrue);
      expect(listed.isDraft, isFalse);
      expect(listed.listingLabel, 'معروض في السوق');
    });

    test('an unlisted office is hidden but still operating', () {
      final unlisted = profile(status: 'active', listingStatus: 'unlisted');

      expect(unlisted.isListed, isFalse);
      expect(unlisted.isDraft, isFalse);
      expect(unlisted.listingLabel, 'مسحوب من السوق');
      // Withdrawing a listing does not stop the office working, so the
      // operational label must not follow the listing one.
      expect(unlisted.status, 'active');
    });

    test('a suspended office is off the marketplace whatever its listing', () {
      expect(
        profile(status: 'suspended', listingStatus: 'listed').isListed,
        isFalse,
      );
    });

    test('copyWith preserves the platform-owned listing status', () {
      final draft = profile(listingStatus: 'draft');

      expect(draft.copyWith(name: 'اسم جديد').listingStatus, 'draft');
    });
  });

  test('load surfaces a read failure as an error state', () async {
    repo.failRead = true;

    await cubit.load();

    expect(cubit.state, isA<OfficeProfileError>());
  });

  test('save writes the edit and settles on the stored row', () async {
    await cubit.load();
    repo.profile = profile(name: 'مكتب القاهرة الكبرى');

    await cubit.save(
      const OfficeProfileEdit(
        name: 'مكتب القاهرة الكبرى',
        description: 'وصف محدّث',
        serviceAreas: ['القاهرة', 'الجيزة'],
      ),
    );

    expect(repo.savedEdit?.name, 'مكتب القاهرة الكبرى');
    expect(repo.savedEdit?.serviceAreas, ['القاهرة', 'الجيزة']);
    final state = cubit.state;
    expect(state, isA<OfficeProfileLoaded>());
    expect((state as OfficeProfileLoaded).profile.name, 'مكتب القاهرة الكبرى');
    expect(state.isSaving, isFalse);
  });

  test('a rejected save keeps the loaded profile on screen', () async {
    await cubit.load();
    repo.failWrite = true;

    final seen = <OfficeProfileState>[];
    final sub = cubit.stream.listen(seen.add);

    await cubit.save(
      const OfficeProfileEdit(
        name: 'اسم جديد',
        description: '',
        serviceAreas: [],
      ),
    );
    // The last two emits happen synchronously in the catch block, so their
    // delivery is still queued as a microtask when save() returns.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // The failure is announced so the screen can show a snack bar, but the form
    // is never replaced by a full-screen error — that would discard the
    // operator's unsaved edits.
    expect(seen.whereType<OfficeProfileActionFailure>(), isNotEmpty);
    expect(seen.whereType<OfficeProfileError>(), isEmpty);
    expect(cubit.state, isA<OfficeProfileLoaded>());
    expect((cubit.state as OfficeProfileLoaded).profile.name, 'مكتب القاهرة');
  });

  test('save before load is a no-op', () async {
    await cubit.save(
      const OfficeProfileEdit(name: 'اسم', description: '', serviceAreas: []),
    );

    expect(repo.savedEdit, isNull);
    expect(cubit.state, isA<OfficeProfileInitial>());
  });

  group('marketplace completeness', () {
    test('is complete when every card field is filled', () {
      expect(profile().missingMarketplaceFields, isEmpty);
    });

    test('names each blank field', () {
      final incomplete = profile(
        description: '   ',
        logoUrl: null,
        serviceAreas: const [],
      );

      expect(incomplete.missingMarketplaceFields, [
        'وصف المكتب',
        'شعار المكتب',
        'مناطق الخدمة',
      ]);
    });
  });
}

class _FakeRepo implements OfficeProfileRepository {
  late OfficeProfile profile;
  OfficeProfileEdit? savedEdit;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<OfficeProfile> getProfile() async {
    if (failRead) throw Exception('تعذر قراءة بيانات المكتب.');
    return profile;
  }

  @override
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit) async {
    if (failWrite) throw Exception('لا تملك صلاحية تعديل بيانات المكتب.');
    savedEdit = edit;
    return profile;
  }
}
