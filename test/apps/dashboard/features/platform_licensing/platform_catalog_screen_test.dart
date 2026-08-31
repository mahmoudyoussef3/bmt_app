import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_catalog_screen.dart';

/// الخطط والباقات is two screens: a gallery of plan cards, and the workspace
/// one opens into. Both have to hold at a short console window — the gallery
/// because a grid of cards is taller than the fold, the workspace because a
/// plan's feature list is longer still.
///
/// The other thing worth locking is the edit buffer: it lives in the screen so
/// leaving a plan with unsaved values has to ask first.

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
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<PlatformLicensingCubit>.value(
            value: _FakeLicensingCubit(state),
            child: const Scaffold(body: PlatformCatalogScreen()),
          ),
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
  double textScale = 1.0,
}) async {
  await _pumpScreen(tester, state, size: size, textScale: textScale);

  // An overflowing Row/Column throws during paint in debug builds and the
  // binding captures it, so a null exception here is a genuine assertion.
  expect(
    tester.takeException(),
    isNull,
    reason:
        'الخطط والباقات overflowed at ${size.width}×${size.height} '
        'at ${textScale}x text',
  );
}

void main() {
  group('PlatformCatalogScreen layout', () {
    for (final size in _sizes) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with a '
          'plan open', (tester) async {
        await _expectNoOverflow(tester, _state(), size: size);
      });

      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} on the '
          'gallery', (tester) async {
        await _expectNoOverflow(
          tester,
          _state(withSelection: false),
          size: size,
        );
      });

      // The workspace runs on fixed-ish lanes — an identity column, a source
      // chip, a control lane — and a fixed lane is exactly what an Arabic label
      // at 1.6× overruns. Pumping at the scale is the cheapest way to find it.
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with a '
          'plan open at 1.6× text', (tester) async {
        await _expectNoOverflow(tester, _state(), size: size, textScale: 1.6);
      });
    }

    testWidgets('the gallery scrolls to the plans past the fold', (
      tester,
    ) async {
      await _expectNoOverflow(
        tester,
        _state(withSelection: false),
        size: const Size(1440, 760),
      );

      final last = find.text('الباقة رقم 12');
      expect(last, findsOneWidget);

      // The grid is taller than the window, so the last card starts under the
      // fold. It has to be reachable rather than clipped.
      final page = find
          .ancestor(of: last, matching: find.byType(Scrollable))
          .first;
      final viewport = tester.getRect(page);
      expect(viewport.contains(tester.getCenter(last)), isFalse);

      await tester.scrollUntilVisible(last, 200, scrollable: page);
      await tester.pumpAndSettle();

      expect(viewport.contains(tester.getCenter(last)), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening a plan replaces the gallery with its workspace', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      // The workspace owns the whole width — the gallery's own controls are
      // gone, and the way back is a named button rather than a bare arrow.
      expect(find.text('كل الباقات'), findsOneWidget);
      expect(find.text('باقة جديدة'), findsNothing);
    });
  });

  group('PlatformCatalogScreen editing', () {
    testWidgets('a clean plan offers no save bar at all', (tester) async {
      await _pumpScreen(tester, _state());

      // Not a disabled save button: nothing is pending, so there is nothing to
      // put on screen.
      expect(find.textContaining('تعديل غير محفوظ'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'حفظ'), findsNothing);
    });

    testWidgets('changing a value raises the save bar with its note field', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('تعديل غير محفوظ'), findsOneWidget);
      // The note is optional and inline — saving never opens a modal asking
      // for a reason the RPC does not require.
      expect(
        find.widgetWithText(TextField, 'ملاحظة للسجل (اختيارية)'),
        findsOneWidget,
      );
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

    testWidgets('leaving the workspace while dirty asks first', (tester) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('كل الباقات'));
      await tester.pumpAndSettle();

      expect(find.text('تعديلات غير محفوظة'), findsOneWidget);
      expect(find.text('البقاء هنا'), findsOneWidget);
    });
  });

  group('PlatformCatalogScreen filtering', () {
    testWidgets('a status filter narrows the gallery and counts what is left', (
      tester,
    ) async {
      await _pumpScreen(tester, _state(withSelection: false));

      await tester.tap(find.textContaining('مسودات'));
      await tester.pumpAndSettle();

      // 12 plans, every third a draft.
      expect(find.text('4 من 12 باقة'), findsOneWidget);
      expect(find.text('الباقة رقم 4'), findsNothing);
    });

    testWidgets('the feature editor can show only what the plan sets', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.textContaining('المضبوطة في الباقة'));
      await tester.pumpAndSettle();

      expect(find.text('يُعرض 3 من 22'), findsOneWidget);
    });

    testWidgets('the complement of "set here" is a place you can go', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      await tester.tap(find.textContaining('تتبع الافتراضي'));
      await tester.pumpAndSettle();

      expect(find.text('يُعرض 19 من 22'), findsOneWidget);
    });

    testWidgets('the feature editor can be narrowed to one category', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      // The category axis is a named dropdown, not a row of bare chips: it has
      // to say WHICH axis it narrows before it is opened.
      await tester.tap(find.textContaining('التصنيف:'));
      await tester.pumpAndSettle();

      // 22 features, alternating categories: 11 in التشغيل.
      await tester.tap(find.text('التشغيل (11)').last);
      await tester.pumpAndSettle();

      expect(find.text('يُعرض 11 من 22'), findsOneWidget);
      expect(find.text('المالية'), findsNothing);
    });

    testWidgets(
      'an applied filter is named, and clearing it restores the list',
      (tester) async {
        await _pumpScreen(tester, _state());

        await tester.tap(find.textContaining('المضبوطة في الباقة'));
        await tester.pumpAndSettle();

        // Spelled out, not counted — "١ فلتر" makes the operator reopen the
        // toolbar to find out which one.
        expect(find.text('المضبوطة في الباقة'), findsOneWidget);

        await tester.tap(find.text('مسح التصفية'));
        await tester.pumpAndSettle();

        expect(find.text('يُعرض 22 من 22'), findsOneWidget);
      },
    );

    testWidgets('a category heading returns its whole group to the default', (
      tester,
    ) async {
      await _pumpScreen(tester, _state());

      expect(find.text('إرجاع الكل للافتراضي'), findsWidgets);

      await tester.tap(find.text('إرجاع الكل للافتراضي').first);
      await tester.pumpAndSettle();

      // Every value the plan set in that category is now an unsaved removal.
      expect(find.textContaining('تعديل غير محفوظ'), findsOneWidget);
    });
  });
}
