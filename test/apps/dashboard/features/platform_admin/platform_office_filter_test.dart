import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The office list's search and filtering.
///
/// The rule these all defend is that the two status axes stay independent: an
/// office can be operationally `active` and still absent from the marketplace,
/// and a filter that conflated the two would hide exactly the offices this
/// screen exists to find.
void main() {
  PlatformOffice office({
    String id = 'office-a',
    String name = 'مكتب الإسكندرية',
    String slug = 'alex-office',
    String status = 'active',
    String listingStatus = 'listed',
    List<String> serviceAreas = const ['الإسكندرية'],
    String? ownerName,
    String? ownerUsername,
  }) => PlatformOffice(
    id: id,
    name: name,
    slug: slug,
    description: 'نقل يومي',
    serviceAreas: serviceAreas,
    status: status,
    listingStatus: listingStatus,
    rating: 0,
    ratingsCount: 0,
    operators: 1,
    drivers: 0,
    routes: 0,
    ownerName: ownerName,
    ownerUsername: ownerUsername,
  );

  final alex = office();
  final cairo = office(
    id: 'office-b',
    name: 'مكتب القاهرة',
    slug: 'cairo-office',
    listingStatus: 'draft',
    serviceAreas: const ['القاهرة', 'الجيزة'],
    ownerName: 'أحمد سمير',
    ownerUsername: 'ops.cairo',
  );
  final suspended = office(
    id: 'office-c',
    name: 'مكتب أسيوط',
    slug: 'asyut-office',
    status: 'suspended',
    listingStatus: 'unlisted',
    serviceAreas: const ['أسيوط'],
  );

  final all = [alex, cairo, suspended];

  group('an empty filter', () {
    test('is empty and passes everything through', () {
      const filter = PlatformOfficeFilter();

      expect(filter.isEmpty, isTrue);
      expect(filter.apply(all), equals(all));
    });
  });

  group('search', () {
    test('matches on office name', () {
      const filter = PlatformOfficeFilter(query: 'القاهرة');

      expect(filter.apply(all).map((o) => o.id), ['office-b']);
    });

    test('matches on slug, which is how offices are named elsewhere', () {
      const filter = PlatformOfficeFilter(query: 'asyut');

      expect(filter.apply(all).map((o) => o.id), ['office-c']);
    });

    test('matches on the owner, who is who the platform actually spoke to', () {
      expect(
        const PlatformOfficeFilter(query: 'أحمد').apply(all).map((o) => o.id),
        ['office-b'],
      );
      expect(
        const PlatformOfficeFilter(
          query: 'ops.cairo',
        ).apply(all).map((o) => o.id),
        ['office-b'],
      );
    });

    test('matches on a service area', () {
      const filter = PlatformOfficeFilter(query: 'الجيزة');

      expect(filter.apply(all).map((o) => o.id), ['office-b']);
    });

    test('is case-insensitive and ignores surrounding whitespace', () {
      const filter = PlatformOfficeFilter(query: '  ALEX  ');

      expect(filter.apply(all).map((o) => o.id), ['office-a']);
    });

    test('a query matching nothing yields an empty list, not everything', () {
      const filter = PlatformOfficeFilter(query: 'no-such-office');

      expect(filter.apply(all), isEmpty);
    });
  });

  group('status facets', () {
    test('operational status filters on status alone', () {
      const filter = PlatformOfficeFilter(status: 'suspended');

      expect(filter.apply(all).map((o) => o.id), ['office-c']);
    });

    test('listing status filters on listing alone', () {
      const filter = PlatformOfficeFilter(listingStatus: 'draft');

      expect(filter.apply(all).map((o) => o.id), ['office-b']);
    });

    // The point of keeping the axes apart: 'active' must not imply 'listed'.
    test('an active filter still returns offices absent from the market', () {
      const filter = PlatformOfficeFilter(status: 'active');

      expect(filter.apply(all).map((o) => o.id), ['office-a', 'office-b']);
    });

    test('an unlisted filter still returns offices that are operating', () {
      final paused = office(
        id: 'office-d',
        name: 'مكتب طنطا',
        slug: 'tanta-office',
        listingStatus: 'unlisted',
      );

      expect(
        const PlatformOfficeFilter(
          listingStatus: 'unlisted',
        ).apply([...all, paused]).map((o) => o.id),
        ['office-c', 'office-d'],
      );
    });

    test('the facets compose', () {
      const filter = PlatformOfficeFilter(
        status: 'active',
        listingStatus: 'draft',
      );

      expect(filter.apply(all).map((o) => o.id), ['office-b']);
    });

    test('search composes with the facets', () {
      const filter = PlatformOfficeFilter(query: 'مكتب', status: 'suspended');

      expect(filter.apply(all).map((o) => o.id), ['office-c']);
    });
  });

  group('copyWith', () {
    test('clears a facet only when explicitly asked', () {
      const filter = PlatformOfficeFilter(
        query: 'alex',
        status: 'active',
        listingStatus: 'listed',
      );

      // A bare copyWith must not drop what it was not given.
      final narrowed = filter.copyWith(query: 'cairo');
      expect(narrowed.status, 'active');
      expect(narrowed.listingStatus, 'listed');

      expect(filter.copyWith(clearStatus: true).status, isNull);
      expect(filter.copyWith(clearStatus: true).listingStatus, 'listed');
      expect(filter.copyWith(clearListingStatus: true).listingStatus, isNull);
      expect(filter.copyWith(clearListingStatus: true).status, 'active');
    });

    test('is empty again once every facet is cleared', () {
      const filter = PlatformOfficeFilter(status: 'active');

      expect(filter.copyWith(query: '', clearStatus: true).isEmpty, isTrue);
    });
  });

  group('profile completeness', () {
    test('counts more than the publish guard checks', () {
      final thin = PlatformOffice(
        id: 'office-e',
        name: 'مكتب',
        slug: 'thin',
        description: 'وصف',
        serviceAreas: const ['القاهرة'],
        status: 'active',
        listingStatus: 'draft',
        rating: 0,
        ratingsCount: 0,
        operators: 1,
        drivers: 0,
        routes: 0,
      );

      // Publishable, but its card would reach passengers with no logo and no
      // way to make contact — which is the gap this measures.
      expect(thin.canBeListed, isTrue);
      expect(thin.completedProfileFields, 2);
      expect(thin.totalProfileFields, 5);
      expect(thin.profileCompleteness, closeTo(0.4, 0.001));
      expect(
        thin.missingProfileFields,
        containsAll(['الشعار', 'رقم الهاتف', 'البريد الإلكتروني']),
      );
    });

    test('a fully filled office reports complete with nothing missing', () {
      final full = PlatformOffice(
        id: 'office-f',
        name: 'مكتب',
        slug: 'full',
        description: 'وصف',
        serviceAreas: const ['القاهرة'],
        status: 'active',
        listingStatus: 'listed',
        rating: 0,
        ratingsCount: 0,
        operators: 1,
        drivers: 0,
        routes: 0,
        logoUrl: 'https://example.com/logo.png',
        phone: '+201000000000',
        email: 'office@example.com',
      );

      expect(full.profileCompleteness, 1.0);
      expect(full.missingProfileFields, isEmpty);
    });

    test('blank strings do not count as filled', () {
      final blank = PlatformOffice(
        id: 'office-g',
        name: 'مكتب',
        slug: 'blank',
        description: '   ',
        serviceAreas: const [],
        status: 'active',
        listingStatus: 'draft',
        rating: 0,
        ratingsCount: 0,
        operators: 0,
        drivers: 0,
        routes: 0,
        logoUrl: '  ',
        phone: '',
      );

      expect(blank.completedProfileFields, 0);
      expect(blank.canBeListed, isFalse);
    });
  });

  group('ownerLabel', () {
    test('prefers the full name', () {
      expect(
        office(ownerName: 'أحمد', ownerUsername: 'ops.a').ownerLabel,
        'أحمد',
      );
    });

    test('falls back to the login handle when there is no full name', () {
      expect(
        office(ownerName: '  ', ownerUsername: 'ops.a').ownerLabel,
        'ops.a',
      );
    });

    // An office nobody can sign in to is a real state, and reads as absent
    // rather than as a blank name.
    test('is null when the office has no active admin at all', () {
      expect(office().ownerLabel, isNull);
    });
  });
}
