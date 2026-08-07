import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';

/// The catalog screen's narrowing lives entirely in [PlatformLicensingLoaded],
/// so it can be tested without standing up the console's 25 use cases.

CatalogFeature _feature({
  required String key,
  String category = 'comms',
  String name = 'ميزة',
  String status = 'active',
  bool enforced = true,
  int sortOrder = 10,
  String description = '',
  String nameEn = '',
}) {
  return CatalogFeature(
    key: key,
    nameAr: name,
    nameEn: nameEn,
    categoryKey: category,
    valueType: 'boolean',
    defaultValue: true,
    status: status,
    isEnforced: enforced,
    descriptionAr: description,
    sortOrder: sortOrder,
  );
}

PlatformLicensingLoaded _loaded({
  List<CatalogFeature>? features,
  List<FeatureCategory>? categories,
  String search = '',
  String? category,
  String? enforcement,
  String? status,
  String? selected,
}) {
  return PlatformLicensingLoaded(
    catalog: FeatureCatalog(
      categories:
          categories ??
          const [
            // Deliberately not alphabetical: the screen must follow the
            // catalog's declared order, not the key's.
            FeatureCategory(key: 'money', nameAr: 'المالية', sortOrder: 1),
            FeatureCategory(key: 'comms', nameAr: 'التواصل والدعم', sortOrder: 2),
          ],
      features:
          features ??
          [
            _feature(key: 'notifications', name: 'التنبيهات'),
            _feature(
              key: 'marketing',
              name: 'أدوات التسويق',
              enforced: false,
              sortOrder: 20,
            ),
            _feature(key: 'finance', name: 'المالية', category: 'money'),
          ],
    ),
    featureSearch: search,
    featureCategoryFilter: category,
    featureEnforcementFilter: enforcement,
    featureStatusFilter: status,
    selectedFeatureKey: selected,
  );
}

void main() {
  group('catalog filtering', () {
    test('no filters shows the whole catalog', () {
      final state = _loaded();
      expect(state.visibleFeatures, hasLength(3));
      expect(state.hasFeatureFilters, isFalse);
      expect(state.featureFilterLabels, isEmpty);
    });

    test('search matches key, Arabic name, English name and description', () {
      final features = [
        _feature(key: 'push_notifications', name: 'الإشعارات الفورية'),
        _feature(key: 'wallet', name: 'المحفظة', nameEn: 'Customer wallet'),
        _feature(
          key: 'sla',
          name: 'مستوى الدعم',
          description: 'زمن الاستجابة المتعهَّد به',
        ),
      ];

      expect(
        _loaded(features: features, search: 'push').visibleFeatures.single.key,
        'push_notifications',
      );
      expect(
        _loaded(features: features, search: 'المحفظة').visibleFeatures.single.key,
        'wallet',
      );
      expect(
        _loaded(features: features, search: 'wallet').visibleFeatures.single.key,
        'wallet',
      );
      expect(
        _loaded(features: features, search: 'الاستجابة').visibleFeatures.single.key,
        'sla',
      );
    });

    test('the enforcement axis splits the two counts the KPI tiles show', () {
      expect(
        _loaded(enforcement: 'enforced').visibleFeatures.map((f) => f.key),
        containsAll(['notifications', 'finance']),
      );
      expect(
        _loaded(enforcement: 'declared').visibleFeatures.single.key,
        'marketing',
      );
    });

    test('category and status narrow independently, and combine', () {
      expect(
        _loaded(category: 'money').visibleFeatures.single.key,
        'finance',
      );

      final withKilled = [
        _feature(key: 'a'),
        _feature(key: 'b', status: 'disabled'),
        _feature(key: 'c', status: 'disabled', category: 'money'),
      ];
      expect(
        _loaded(features: withKilled, status: 'disabled').visibleFeatures,
        hasLength(2),
      );
      expect(
        _loaded(
          features: withKilled,
          status: 'disabled',
          category: 'money',
        ).visibleFeatures.single.key,
        'c',
      );
    });

    test('active filters are spelled out, never counted', () {
      final state = _loaded(
        search: ' تنبيه ',
        category: 'comms',
        enforcement: 'declared',
        status: 'disabled',
      );

      expect(state.hasFeatureFilters, isTrue);
      expect(state.featureFilterLabels, [
        'بحث: «تنبيه»',
        'التواصل والدعم',
        'معلنة فقط',
        'موقوفة على مستوى المنصة',
      ]);
    });
  });

  group('catalog grouping', () {
    test('groups follow the catalog category order, not the key order', () {
      final groups = _loaded().visibleFeatureGroups;
      expect(groups.map((g) => g.key), ['money', 'comms']);
      expect(groups.first.features.single.key, 'finance');
      expect(groups.last.features.map((f) => f.key), [
        'notifications',
        'marketing',
      ]);
    });

    test('a feature whose category row is missing is still listed', () {
      final state = _loaded(
        features: [_feature(key: 'orphan', category: 'ghost')],
      );

      final groups = state.visibleFeatureGroups;
      expect(groups.single.key, 'ghost');
      // Falls back to the raw key rather than dropping the row.
      expect(groups.single.nameAr, 'ghost');
      expect(groups.single.features.single.key, 'orphan');
    });

    test('empty groups are dropped so filtering never leaves headers behind', () {
      final groups = _loaded(category: 'money').visibleFeatureGroups;
      expect(groups, hasLength(1));
      expect(groups.single.key, 'money');
    });
  });

  group('selection', () {
    test('resolves through the catalog, so a reload keeps the open row', () {
      expect(_loaded(selected: 'finance').selectedFeature?.nameAr, 'المالية');
    });

    test('a key that no longer exists reads as no selection', () {
      expect(_loaded(selected: 'deleted').selectedFeature, isNull);
      expect(_loaded().selectedFeature, isNull);
    });

    test('selection survives a filter that hides the row', () {
      // The detail pane must not blank out the moment the operator types a
      // search that excludes what they are reading.
      final state = _loaded(selected: 'finance', category: 'comms');
      expect(state.visibleFeatures.map((f) => f.key), isNot(contains('finance')));
      expect(state.selectedFeature?.key, 'finance');
    });
  });
}
