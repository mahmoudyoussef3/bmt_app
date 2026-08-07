import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_plans_screen.dart';

/// الخطط والباقات has one layout that has to hold: a plan list taller than the
/// window beside an open plan whose feature list is longer still. The list used
/// to be a plain `Column` in a viewport-height row, so it clipped — the console
/// reported "BOTTOM OVERFLOWED BY 90 PIXELS" over the last plan in the list.
///
/// The other thing worth locking is the edit buffer: it lives in the screen so
/// the list can refuse to move to another plan while it is dirty.

/// Window sizes the console is actually used at, height first.
const _sizes = <Size>[
  Size(1680, 1050),
  Size(1440, 760),
  Size(1180, 700),
  Size(900, 640),
];

class _FakeLicensingCubit extends Cubit<PlatformLicensingState>
    implements PlatformLicensingCubit {
  _FakeLicensingCubit(super.initialState);

  // The screen only reads state here; every action it can fire is a no-op.
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

CatalogFeature _feature(int i) => CatalogFeature(
  key: 'feature.$i',
  nameAr: 'ميزة تشغيلية طويلة الاسم رقم ${i + 1}',
  nameEn: 'operational feature $i',
  categoryKey: i.isEven ? 'ops' : 'finance',
  valueType: switch (i % 3) {
    0 => 'boolean',
    1 => 'limit',
    _ => 'config',
  },
  defaultValue: switch (i % 3) {
    0 => false,
    1 => 10,
    _ => '',
  },
  status: 'active',
  isEnforced: i % 4 != 0,
  sortOrder: i,
);

const _catalog = FeatureCatalog(
  categories: [
    FeatureCategory(key: 'ops', nameAr: 'التشغيل', sortOrder: 1),
    FeatureCategory(key: 'finance', nameAr: 'المالية', sortOrder: 2),
  ],
  features: [],
);

FeatureCatalog get _fullCatalog => FeatureCatalog(
  categories: _catalog.categories,
  features: [for (var i = 0; i < 22; i++) _feature(i)],
);

LicensingPlan _plan(int i) => LicensingPlan(
  id: 'plan-$i',
  key: 'plan-key-$i',
  nameAr: 'الباقة رقم ${i + 1}',
  taglineAr: 'وصف مختصر للباقة رقم ${i + 1} يشرح لمن هي موجّهة',
  status: switch (i % 3) {
    0 => 'active',
    1 => 'draft',
    _ => 'archived',
  },
  isPublic: i.isEven,
  priceMonthly: i.isEven ? 1500 + i * 250 : null,
  trialDays: i.isEven ? 14 : 0,
  officeCount: i,
  revision: i,
);

PlanDetail get _detail => PlanDetail(
  plan: _plan(0),
  values: {
    'feature.0': true,
    'feature.1': 40,
    'feature.3': FeatureValue.unlimited,
  },
  offices: [
    for (var i = 0; i < 6; i++)
      PlanOfficeRef(
        officeId: 'office-$i',
        name: 'مكتب النقل السريع للرحلات رقم ${i + 1}',
        status: i.isEven ? 'active' : 'trialing',
      ),
  ],
  revisions: [
    for (var i = 0; i < 5; i++)
      PlanRevision(
        id: 'revision-$i',
        revision: 5 - i,
        createdAt: DateTime(2026, 8, 1 + i),
        reason: 'تعديل بعد مراجعة تجارية مع المكتب',
        snapshot: {
          'features': {'feature.0': false, 'feature.1': 25},
        },
      ),
  ],
);

PlatformLicensingLoaded _state({bool withSelection = true}) =>
    PlatformLicensingLoaded(
      catalog: _fullCatalog,
      // More plans than a short window can show: the list has to scroll rather
      // than clip its last rows.
      plans: [for (var i = 0; i < 12; i++) _plan(i)],
      selectedPlan: withSelection ? _detail : null,
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  PlatformLicensingLoaded state, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<PlatformLicensingCubit>.value(
          value: _FakeLicensingCubit(state),
          child: const Scaffold(body: PlatformPlansScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectNoOverflow(
  WidgetTester tester,
  PlatformLicensingLoaded state, {
  required Size size,
}) async {
  await _pumpScreen(tester, state, size: size);

  // An overflowing Row/Column throws during paint in debug builds and the
  // binding captures it, so a null exception here is a genuine assertion.
  expect(
    tester.takeException(),
    isNull,
    reason: 'الخطط والباقات overflowed at ${size.width}×${size.height}',
  );
}

void main() {
  group('PlatformPlansScreen layout', () {
    for (final size in _sizes) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with a '
          'plan open', (tester) async {
        await _expectNoOverflow(tester, _state(), size: size);
      });

      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with the '
          'detail placeholder', (tester) async {
        await _expectNoOverflow(
          tester,
          _state(withSelection: false),
          size: size,
        );
      });
    }

    testWidgets('the plan list scrolls to the plans past the fold', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1440, 760));

      final last = find.text('الباقة رقم 12');
      expect(last, findsOneWidget);

      // The list is longer than its pane, so the last plan starts under the
      // fold. Before the fix it stayed there — the column simply clipped.
      final master = find
          .ancestor(of: last, matching: find.byType(Scrollable))
          .first;
      final viewport = tester.getRect(master);
      expect(viewport.contains(tester.getCenter(last)), isFalse);

      await tester.scrollUntilVisible(last, 200, scrollable: master);
      await tester.pumpAndSettle();

      expect(viewport.contains(tester.getCenter(last)), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('PlatformPlansScreen editing', () {
    testWidgets('a clean plan offers no unsaved-changes bar', (tester) async {
      await _pumpScreen(tester, _state());

      expect(find.textContaining('تعديل غير محفوظ'), findsNothing);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'حفظ'),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('changing a value raises the unsaved bar and enables save', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('تعديل غير محفوظ'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'حفظ').first,
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('discarding restores the stored values', (tester) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('تعديل غير محفوظ'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'تجاهل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تعديل غير محفوظ'), findsNothing);
    });

    testWidgets('moving to another plan while dirty asks first', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('الباقة رقم 4'));
      await tester.pumpAndSettle();

      expect(find.text('تعديلات غير محفوظة'), findsOneWidget);
      expect(find.text('البقاء هنا'), findsOneWidget);
    });
  });

  group('PlatformPlansScreen filtering', () {
    testWidgets('a status filter narrows the list and counts what is left', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.textContaining('مسودات'));
      await tester.pumpAndSettle();

      // 12 plans, every third a draft. The open plan still names itself in the
      // detail header, so the count is what the filter is judged on.
      expect(find.text('4 من 12 باقة'), findsOneWidget);
      expect(find.text('الباقة رقم 4'), findsNothing);
    });

    testWidgets('the features tab can show only what the plan sets', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.textContaining('المضبوطة في الباقة'));
      await tester.pumpAndSettle();

      expect(find.text('يُعرض 3 من 22'), findsOneWidget);
    });
  });
}
