import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/office_onboarding.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office_details.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/repositories/platform_admin_repository.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/usecases/platform_admin_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Search, filtering and the details panel, driven through the cubit.
///
/// The behaviours that matter here are the ones a naive implementation loses:
/// a filter that survives a publish, a panel that refreshes when the office
/// underneath it changes, and a late response that does not overwrite the office
/// the operator has since moved to.
void main() {
  late _FakeRepo repo;
  late PlatformAdminCubit cubit;

  PlatformOffice office({
    String id = 'office-a',
    String name = 'مكتب الإسكندرية',
    String slug = 'alex-office',
    String status = 'active',
    String listingStatus = 'draft',
    String description = 'نقل يومي',
    List<String> serviceAreas = const ['الإسكندرية'],
  }) => PlatformOffice(
    id: id,
    name: name,
    slug: slug,
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

  final alex = office();
  final cairo = office(
    id: 'office-b',
    name: 'مكتب القاهرة',
    slug: 'cairo-office',
    listingStatus: 'listed',
  );

  PlatformOfficeDetails detailsFor(
    PlatformOffice source, {
    PlatformOfficeMarketplacePreview? marketplace,
    List<PlatformOfficeOperator> operators = const [],
  }) => PlatformOfficeDetails(
    office: source,
    counts: const PlatformOfficeCounts(
      operators: 1,
      drivers: 2,
      vehicles: 3,
      routes: 4,
      trips: 5,
      bookings: 6,
      reviews: 7,
    ),
    operators: operators,
    marketplace: marketplace,
  );

  setUp(() {
    repo = _FakeRepo()..offices = [alex, cairo];
    cubit = PlatformAdminCubit(
      getOffices: GetPlatformOfficesUseCase(repo),
      getAnalytics: GetPlatformAnalyticsUseCase(repo),
      getOfficeDetails: GetPlatformOfficeDetailsUseCase(repo),
      onboardOffice: OnboardOfficeUseCase(repo),
      setListing: SetOfficeListingUseCase(repo),
      setStatus: SetOfficeStatusUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  PlatformAdminLoaded loaded() => cubit.state as PlatformAdminLoaded;

  group('search and filtering', () {
    test('narrows the visible list without touching the loaded list', () async {
      await cubit.load();

      cubit.search('القاهرة');

      // The summary counts must keep describing the platform, not the search.
      expect(loaded().visibleOffices.map((o) => o.id), ['office-b']);
      expect(loaded().offices, hasLength(2));
      expect(loaded().listedCount, 1);
    });

    test('filters the two status axes independently', () async {
      await cubit.load();

      cubit.filterByListingStatus('draft');
      expect(loaded().visibleOffices.map((o) => o.id), ['office-a']);

      cubit.filterByStatus('active');
      expect(loaded().visibleOffices.map((o) => o.id), ['office-a']);

      cubit.filterByListingStatus(null);
      expect(loaded().visibleOffices, hasLength(2));
      expect(loaded().filter.status, 'active');
    });

    test('clearFilters restores the full list', () async {
      await cubit.load();
      cubit.search('القاهرة');
      cubit.filterByStatus('active');

      cubit.clearFilters();

      expect(loaded().filter.isEmpty, isTrue);
      expect(loaded().visibleOffices, hasLength(2));
    });

    test('filtering does not re-hit the network', () async {
      await cubit.load();
      final before = repo.listCalls;

      cubit.search('القاهرة');
      cubit.filterByStatus('active');
      cubit.clearFilters();

      expect(repo.listCalls, before);
    });

    // The regression a naive `emit(PlatformAdminLoaded(refreshed))` introduces.
    test('a filter survives a publish that reloads the list', () async {
      await cubit.load();
      cubit.search('القاهرة');

      await cubit.setListing('office-b', 'unlisted');

      expect(loaded().filter.query, 'القاهرة');
      expect(loaded().visibleOffices.map((o) => o.id), ['office-b']);
    });

    test('awaitingListingCount counts active offices off the market', () async {
      await cubit.load();

      // alex is active+draft; cairo is active+listed.
      expect(loaded().awaitingListingCount, 1);
    });
  });

  group('office details', () {
    test('opens with a loading panel, then the fetched details', () async {
      await cubit.load();
      repo.details = detailsFor(alex);

      final pending = cubit.openDetails('office-a');
      expect(loaded().selection?.officeId, 'office-a');
      expect(loaded().selection?.isLoading, isTrue);
      expect(loaded().selection?.details, isNull);

      await pending;

      expect(loaded().selection?.isLoading, isFalse);
      expect(loaded().selection?.details?.counts.vehicles, 3);
      expect(loaded().selection?.details?.counts.bookings, 6);
      expect(repo.detailCalls, ['office-a']);
    });

    test('surfaces a details failure without losing the list', () async {
      await cubit.load();
      repo.failDetails = true;

      await cubit.openDetails('office-a');

      expect(loaded().selection?.error, 'details failed');
      expect(loaded().selection?.details, isNull);
      expect(loaded().offices, hasLength(2));
    });

    test('closeDetails clears the panel', () async {
      await cubit.load();
      repo.details = detailsFor(alex);
      await cubit.openDetails('office-a');

      cubit.closeDetails();

      expect(loaded().selection, isNull);
    });

    // A slow first response must not land on top of the office the operator
    // switched to in the meantime.
    test('a superseded fetch does not overwrite the newer selection', () async {
      await cubit.load();
      repo.details = detailsFor(alex);
      repo.detailDelay = const Duration(milliseconds: 40);

      final first = cubit.openDetails('office-a');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      repo.details = detailsFor(cairo);
      repo.detailDelay = Duration.zero;
      await cubit.openDetails('office-b');
      await first;

      expect(loaded().selection?.officeId, 'office-b');
      expect(loaded().selection?.details?.office.id, 'office-b');
    });

    test('publishing from the panel refreshes what the panel shows', () async {
      await cubit.load();
      repo.details = detailsFor(alex);
      await cubit.openDetails('office-a');
      expect(loaded().selection?.details?.office.listingStatus, 'draft');

      // The office is published; both the list and the open panel must catch up.
      final published = office(listingStatus: 'listed');
      repo.offices = [published, cairo];
      repo.details = detailsFor(
        published,
        marketplace: const PlatformOfficeMarketplacePreview(
          name: 'مكتب الإسكندرية',
          slug: 'alex-office',
          description: 'نقل يومي',
          serviceAreas: ['الإسكندرية'],
          rating: 0,
          ratingsCount: 0,
        ),
      );

      await cubit.setListing('office-a', 'listed');

      expect(loaded().selection?.details?.office.listingStatus, 'listed');
      expect(loaded().selection?.details?.isOnMarketplace, isTrue);
    });

    test('a failed panel refresh keeps the panel it already had', () async {
      await cubit.load();
      repo.details = detailsFor(alex);
      await cubit.openDetails('office-a');

      repo.failDetails = true;
      await cubit.setListing('office-a', 'listed');

      // The action succeeded, so it must not be reported as a failure, and the
      // panel keeps its last good content rather than blanking.
      expect(loaded().selection?.details, isNotNull);
      expect(repo.listingCalls, [('office-a', 'listed')]);
    });

    test(
      'the use case refuses an empty office id before the network',
      () async {
        await cubit.load();
        final before = repo.detailCalls.length;

        expect(
          () => GetPlatformOfficeDetailsUseCase(repo).call('  '),
          throwsArgumentError,
        );
        expect(repo.detailCalls.length, before);
      },
    );
  });

  group('marketplace visibility', () {
    test('a listed office reports a preview', () {
      final details = detailsFor(
        office(listingStatus: 'listed'),
        marketplace: const PlatformOfficeMarketplacePreview(
          name: 'مكتب',
          slug: 'slug',
          description: 'وصف',
          serviceAreas: ['القاهرة'],
          rating: 4.5,
          ratingsCount: 12,
        ),
      );

      expect(details.isOnMarketplace, isTrue);
      expect(details.marketplaceAbsenceReason, isNull);
    });

    // Absence has two very different causes and two different remedies, so the
    // panel names the axis at fault rather than saying "not visible".
    test('a draft office explains that it was never published', () {
      final details = detailsFor(office(listingStatus: 'draft'));

      expect(details.isOnMarketplace, isFalse);
      expect(details.marketplaceAbsenceReason, contains('قيد التجهيز'));
    });

    test('a withdrawn office explains that it was pulled', () {
      final details = detailsFor(office(listingStatus: 'unlisted'));

      expect(details.marketplaceAbsenceReason, contains('سحب'));
    });

    test('a suspended office blames the operational axis, not listing', () {
      final details = detailsFor(
        office(status: 'suspended', listingStatus: 'listed'),
      );

      expect(details.isOnMarketplace, isFalse);
      expect(details.marketplaceAbsenceReason, contains('موقوف'));
    });
  });

  group('operators', () {
    test('labels the owner and the support agent distinctly', () {
      const owner = PlatformOfficeOperator(
        username: 'ops.alex',
        fullName: 'أحمد سمير',
        role: 'dashboard_admin',
        status: 'active',
      );
      const agent = PlatformOfficeOperator(
        username: 'support.alex',
        fullName: '',
        role: 'support_agent',
        status: 'disabled',
      );

      expect(owner.isOwner, isTrue);
      expect(owner.displayName, 'أحمد سمير');
      expect(owner.roleLabel, 'مالك المكتب');
      expect(owner.isActive, isTrue);

      expect(agent.isOwner, isFalse);
      // No full name recorded: falls back to the login handle.
      expect(agent.displayName, 'support.alex');
      expect(agent.statusLabel, 'معطّل');
    });
  });

  group('backend rejection', () {
    test('an incomplete office surfaces the real server message', () async {
      await cubit.load();
      repo.listingError = Exception(
        'أكمل وصف المكتب ومناطق الخدمة قبل عرضه في السوق.',
      );

      final states = <PlatformAdminState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.setListing('office-a', 'listed');
      // Bloc delivers on a microtask, so let the queue drain before cancelling.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final failure = states.whereType<PlatformAdminActionFailure>().single;
      expect(failure.message, contains('أكمل وصف المكتب'));
      // The rejection is surfaced, never worked around.
      expect(
        loaded().offices.firstWhere((o) => o.id == 'office-a').listingStatus,
        'draft',
      );
    });
  });
}

class _FakeRepo implements PlatformAdminRepository {
  List<PlatformOffice> offices = const [];
  PlatformOfficeDetails? details;
  OfficeOnboardingResult? result;

  bool failDetails = false;
  Object? listingError;
  Duration detailDelay = Duration.zero;

  int listCalls = 0;
  final List<String> detailCalls = [];
  final List<int> analyticsCalls = [];
  final List<(String, String)> listingCalls = [];
  final List<(String, String)> statusCalls = [];

  PlatformAnalytics? analytics;

  @override
  Future<List<PlatformOffice>> getOffices() async {
    listCalls++;
    return offices;
  }

  @override
  Future<PlatformAnalytics> getAnalytics({int windowDays = 30}) async {
    analyticsCalls.add(windowDays);
    return analytics ??
        PlatformAnalytics(
          windowDays: windowDays,
          totals: const PlatformTotals(),
          trend: const [],
          offices: const {},
        );
  }

  @override
  Future<PlatformOfficeDetails> getOfficeDetails(String officeId) async {
    detailCalls.add(officeId);
    if (detailDelay > Duration.zero) await Future<void>.delayed(detailDelay);
    if (failDetails) throw Exception('details failed');
    return details!;
  }

  @override
  Future<OfficeOnboardingResult> onboardOffice(
    OfficeOnboardingRequest request,
  ) async => result!;

  @override
  Future<void> setListingStatus(String officeId, String listingStatus) async {
    final error = listingError;
    if (error != null) throw error;
    listingCalls.add((officeId, listingStatus));
    // The fake mirrors the server: the list the cubit reloads reflects the write.
    offices = [
      for (final o in offices)
        if (o.id == officeId)
          PlatformOffice(
            id: o.id,
            name: o.name,
            slug: o.slug,
            description: o.description,
            serviceAreas: o.serviceAreas,
            status: o.status,
            listingStatus: listingStatus,
            rating: o.rating,
            ratingsCount: o.ratingsCount,
            operators: o.operators,
            drivers: o.drivers,
            routes: o.routes,
          )
        else
          o,
    ];
  }

  @override
  Future<void> setOfficeStatus(String officeId, String status) async {
    statusCalls.add((officeId, status));
  }
}
