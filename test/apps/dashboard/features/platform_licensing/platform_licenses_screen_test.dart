import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/office_license.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_licenses_screen.dart';

/// التراخيص has to survive its own worst day: a health strip where every signal
/// has rows, a long office list, and a licence panel open beside it — all in a
/// window shorter than that content. The screen used to lay that out in a
/// viewport-height `Column`, so the health cards, the office list and the empty
/// detail placeholder each clipped independently.

/// Window sizes the console is actually used at, height first: a short laptop
/// window is what exposed the clipping.
const _sizes = <Size>[
  Size(1680, 1050),
  Size(1440, 760),
  Size(1180, 700),
  Size(900, 640),
];

class _FakeLicensingCubit extends Cubit<PlatformLicensingState>
    implements PlatformLicensingCubit {
  _FakeLicensingCubit(super.initialState);

  /// Every batch the feature board sent, so a test can assert what the board
  /// decided to save rather than just that it did something.
  final applied = <({List<OfficeFeatureEdit> edits, String reason})>[];

  /// Drives the screen from outside, the way selecting a different office in
  /// the console does.
  void push(PlatformLicensingState next) => emit(next);

  @override
  Future<void> applyFeatureEdits(
    String officeId,
    List<OfficeFeatureEdit> edits,
    String reason,
  ) async => applied.add((edits: edits, reason: reason));

  // The screen only reads state here; every other action it can fire is a
  // no-op.
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

List<Map<String, dynamic>> _healthRows(int count, String prefix) => [
  for (var i = 0; i < count; i++)
    {
      'office_id': '$prefix-$i',
      'office_name': 'مكتب النقل السريع للرحلات رقم ${i + 1}',
      'status': 'past_due',
      'trial_ends_at': '2026-09-0${(i % 9) + 1}T00:00:00Z',
      'name_ar': 'عدد السائقين المسموح به',
      'plan_key': 'professional',
      'feature_key': 'loyalty.points',
      'used': 52,
      'limit': 40,
    },
];

ResolvedFeature _feature(int i, {required String valueType}) => ResolvedFeature(
  key: 'feature.$i',
  value: valueType == 'limit' ? 40 : true,
  valueType: valueType,
  source: i.isEven ? 'plan' : 'override',
  nameAr: 'ميزة تشغيلية طويلة الاسم رقم ${i + 1}',
  categoryKey: 'ops',
  unitAr: 'سائق',
  used: 52,
  sortOrder: i,
);

/// The catalog behind the board: every feature the office resolves, plus the
/// two kinds of row that must behave differently — a numeric limit and a
/// feature the platform has killed for everyone.
final _catalog = FeatureCatalog(
  categories: const [
    FeatureCategory(key: 'ops', nameAr: 'التشغيل', sortOrder: 1),
    FeatureCategory(key: 'finance', nameAr: 'المالية', sortOrder: 2),
  ],
  features: [
    for (var i = 0; i < 24; i++)
      CatalogFeature(
        key: 'feature.$i',
        nameAr: 'ميزة تشغيلية طويلة الاسم رقم ${i + 1}',
        nameEn: 'feature $i',
        categoryKey: i.isEven ? 'ops' : 'finance',
        valueType: i % 3 == 0 ? 'limit' : 'boolean',
        defaultValue: i % 3 == 0 ? 10 : false,
        status: 'active',
        isEnforced: true,
        unitAr: i % 3 == 0 ? 'سائق' : '',
        sortOrder: i,
      ),
    const CatalogFeature(
      key: 'feature.killed',
      nameAr: 'ميزة موقوفة على مستوى المنصة',
      nameEn: 'killed',
      categoryKey: 'ops',
      valueType: 'boolean',
      defaultValue: false,
      status: 'disabled',
      isEnforced: true,
      sortOrder: 99,
    ),
  ],
);

final _detail = OfficeLicenseDetail(
  officeId: 'office-0',
  officeName: 'مكتب النقل السريع للرحلات رقم ١',
  entitlements: EntitlementContext(
    license: const LicenseSummary(
      planKey: 'professional',
      planNameAr: 'الباقة الاحترافية',
      status: 'trialing',
      billingCycle: 'monthly',
      price: 4500,
    ),
    features: {
      for (var i = 0; i < 24; i++)
        'feature.$i': _feature(i, valueType: i % 3 == 0 ? 'limit' : 'boolean'),
    },
    enforcementMode: 'enforcing',
    resolvedAt: DateTime(2026, 8, 7),
  ),
  overrides: [
    for (var i = 0; i < 4; i++)
      FeatureOverride(
        featureKey: 'feature.$i',
        nameAr: 'ميزة تشغيلية طويلة الاسم رقم ${i + 1}',
        value: true,
        planValue: false,
        reason: 'تنازل تجاري متفق عليه مع المكتب عند التعاقد',
        expiresAt: DateTime(2026, 12, 31),
      ),
  ],
  activity: [
    for (var i = 0; i < 12; i++)
      LicenseAuditEntry(
        id: i,
        action: 'override_created',
        entityType: 'override',
        entityRef: 'feature.$i',
        reason: 'تسوية بعد مراجعة الحساب',
        createdAt: DateTime(2026, 8, 1),
      ),
  ],
);

PlatformLicensingLoaded _state({bool withSelection = true}) =>
    PlatformLicensingLoaded(
      catalog: _catalog,
      settings: const LicensingSettings(enforcementMode: 'enforcing'),
      health: LicensingHealth(
        enforcementMode: 'enforcing',
        // The card that was clipped in the report: more rows than it lists.
        soldButDeclared: _healthRows(11, 'sold'),
        trialsEnding: _healthRows(6, 'trial'),
        pastDue: _healthRows(3, 'past'),
        overLimit: _healthRows(7, 'over'),
        overridesExpiring: _healthRows(2, 'ovr'),
        officesWithoutLicense: _healthRows(5, 'none'),
      ),
      licenses: [
        for (var i = 0; i < 18; i++)
          OfficeLicenseRow(
            officeId: 'office-$i',
            officeName: 'مكتب النقل السريع للرحلات رقم ${i + 1}',
            status: i.isEven ? 'active' : 'trialing',
            planNameAr: 'الباقة الاحترافية',
            overLimitCount: i % 4,
            licensingHold: i % 5 == 0 ? 'delisted' : 'none',
          ),
      ],
      selectedOffice: withSelection ? _detail : null,
    );

Future<_FakeLicensingCubit> _expectNoOverflow(
  WidgetTester tester,
  PlatformLicensingLoaded state, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _FakeLicensingCubit(state);
  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<PlatformLicensingCubit>.value(
          value: cubit,
          child: const Scaffold(body: PlatformLicensesScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // An overflowing Row/Column throws during paint in debug builds and the
  // binding captures it, so a null exception here is a genuine assertion.
  expect(
    tester.takeException(),
    isNull,
    reason: 'التراخيص overflowed at ${size.width}×${size.height}',
  );
  return cubit;
}

void main() {
  group('PlatformLicensesScreen layout', () {
    for (final size in _sizes) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with an '
          'office open', (tester) async {
        await _expectNoOverflow(tester, _state(), size: size);
      });

      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with the '
          'directory', (tester) async {
        await _expectNoOverflow(
          tester,
          _state(withSelection: false),
          size: size,
        );
      });
    }

    testWidgets('a signal shows its count, and opens onto every row', (
      tester,
    ) async {
      await _expectNoOverflow(
        tester,
        _state(withSelection: false),
        size: const Size(1680, 1050),
      );

      // The strip is a row of counts: the number is the whole tile, so it is
      // never the thing that gets clipped.
      expect(find.text('11'), findsWidgets);

      await tester.ensureVisible(find.text('مُباعة بلا كود'));
      await tester.tap(find.text('مُباعة بلا كود'));
      await tester.pumpAndSettle();

      // Every row, not the first five and a footnote — the card listing eleven
      // is precisely the one the operator opened the screen for.
      expect(
        find.text('professional — عدد السائقين المسموح به'),
        findsNWidgets(11),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a clean platform shows no signal strip at all', (
      tester,
    ) async {
      await _expectNoOverflow(
        tester,
        PlatformLicensingLoaded(
          settings: const LicensingSettings(enforcementMode: 'enforcing'),
          licenses: _state().licenses,
        ),
        size: const Size(1440, 760),
      );

      // Six cards saying "لا يوجد" is a wall, not a health strip.
      expect(find.text('تجارب تنتهي قريبًا'), findsNothing);
      expect(find.textContaining('لا شيء يحتاج انتباهك الآن'), findsOneWidget);
    });
  });

  group('PlatformLicensesScreen list', () {
    testWidgets('the office list can be searched', (tester) async {
      await _expectNoOverflow(
        tester,
        _state(withSelection: false),
        size: const Size(1680, 1050),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث باسم المكتب أو باقته'),
        'رقم 3',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('مكتب النقل السريع للرحلات رقم 3'), findsOneWidget);
      expect(find.text('مكتب النقل السريع للرحلات رقم 4'), findsNothing);
    });

    testWidgets('the directory yields the whole page once an office is open', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1440, 900));

      // No split pane: the workspace replaces the grid, so the office cards and
      // the signal strip are gone rather than squeezed beside it.
      expect(find.text('فتح الترخيص'), findsNothing);
      expect(find.text('يحتاج انتباهك'), findsNothing);
      expect(find.text('كل المكاتب'), findsOneWidget);
    });
  });

  group('PlatformLicensesScreen workspace', () {
    testWidgets('the six stacked panels are four tabs', (tester) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1440, 900));

      // Only the open tab's body is built — the other three are one press away
      // instead of a scroll away.
      expect(find.text('الاستخدام'), findsWidgets);
      expect(find.text('لا توجد استثناءات'), findsNothing);
      expect(find.text('لا تجاوز على أي حد'), findsNothing);

      await tester.tap(find.text('الاستثناءات'));
      await tester.pumpAndSettle();

      expect(
        find.text('ميزة تشغيلية طويلة الاسم رقم 1'),
        findsOneWidget,
        reason: 'the overrides tab lists this office\'s overrides',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an office opens on its features, not on its meters', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1440, 900));

      // The board is the reason this workspace is opened, so it is the tab an
      // office lands on.
      expect(find.text('الميزات والحدود'), findsWidgets);
      expect(find.byType(Switch), findsWidgets);
      expect(find.text('ميزة تشغيلية طويلة الاسم رقم 2'), findsOneWidget);
    });

    testWidgets('every licence action is visible without a ⋯ menu', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1440, 900));

      // «تعيين باقة» is the most common operation on this screen and used to be
      // two clicks deep inside a panel header's overflow menu.
      expect(find.text('تغيير الباقة'), findsOneWidget);
      expect(find.text('تمديد التجربة'), findsOneWidget);
      expect(find.text('إيقاف مؤقت'), findsOneWidget);
      expect(find.text('إصدار فاتورة'), findsOneWidget);
    });
  });

  group('OfficeFeatureBoard', () {
    /// Every row's control carries a stable key, so a test addresses the
    /// feature it means rather than the nth switch on screen.
    ///
    /// `feature.0` is a limit (40, with 52 in use), `feature.1` and
    /// `feature.2` are switches that resolve on, and `feature.killed` is
    /// disabled platform-wide.
    Finder controlFor(String key) => find.byKey(ValueKey('$key:control'));

    /// Tall enough to hold the whole catalog without scrolling. These tests are
    /// about what the board decides, not about reaching a row; the sizes the
    /// console is actually used at are covered by the layout group above.
    const board = Size(1680, 2600);

    testWidgets('a toggle is a draft: nothing is sent until it is applied', (
      tester,
    ) async {
      final cubit = await _expectNoOverflow(tester, _state(), size: board);

      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();

      expect(
        cubit.applied,
        isEmpty,
        reason: 'a switch must not reach the server on its own',
      );
      expect(find.text('1 تغيير غير محفوظ'), findsOneWidget);
      expect(
        find.textContaining('ميزة تشغيلية طويلة الاسم رقم 2: من مفعّلة إلى'),
        findsOneWidget,
        reason: "the save bar states the change in the operator's words",
      );
    });

    testWidgets('the batch refuses to leave without a reason', (tester) async {
      final cubit = await _expectNoOverflow(tester, _state(), size: board);

      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تطبيق'));
      await tester.pumpAndSettle();

      // `platform_set_override` refuses anything under eight characters, so an
      // unexplained exception must never leave the console either.
      expect(cubit.applied, isEmpty);
      expect(find.textContaining('اكتب سببًا واضحًا'), findsOneWidget);
    });

    testWidgets('one reason covers every change in the batch', (tester) async {
      final cubit = await _expectNoOverflow(tester, _state(), size: board);

      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();
      await tester.tap(controlFor('feature.2'));
      await tester.pumpAndSettle();
      expect(find.text('2 تغييرًا غير محفوظ'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'السبب'),
        'عقد سنوي موقّع مع المكتب',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تطبيق'));
      await tester.pumpAndSettle();

      expect(cubit.applied, hasLength(1));
      expect(cubit.applied.single.edits, hasLength(2));
      expect(cubit.applied.single.reason, 'عقد سنوي موقّع مع المكتب');
      expect(
        find.textContaining('غير محفوظ'),
        findsNothing,
        reason: 'the buffer is dropped once the batch is away',
      );
    });

    testWidgets('flipping a switch back is not a change', (tester) async {
      await _expectNoOverflow(tester, _state(), size: board);

      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();
      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();

      // The bar counts decisions, not gestures — one that counted gestures
      // would teach the operator to ignore it.
      expect(find.textContaining('غير محفوظ'), findsNothing);
    });

    testWidgets('a limit is edited as a number, in its own unit', (
      tester,
    ) async {
      final cubit = await _expectNoOverflow(tester, _state(), size: board);

      expect(find.textContaining('مستخدَم 52 من 40'), findsWidgets);
      expect(
        find.text('سائق'),
        findsWidgets,
        reason: 'the unit rides on the field, not in a legend',
      );

      await tester.enterText(controlFor('feature.0'), '٦٠');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'السبب'),
        'توسعة أسطول متفق عليها',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'تطبيق'));
      await tester.pumpAndSettle();

      // Arabic-Indic digits are what an Arabic keyboard produces, and
      // `int.tryParse` returns null for them.
      expect(cubit.applied.single.edits.single.value, 60);
    });

    testWidgets('a feature the platform killed cannot be granted here', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: board);

      expect(
        tester.widget<Switch>(controlFor('feature.killed')).onChanged,
        isNull,
        reason: 'the resolver would overrule the override on the next read',
      );
      expect(
        find.textContaining('موقوفة على مستوى المنصة — لا يمكن تفعيلها'),
        findsOneWidget,
      );
    });

    testWidgets(
      "moving to another office does not carry the first one's draft",
      (tester) async {
        final cubit = await _expectNoOverflow(tester, _state(), size: board);

        await tester.tap(controlFor('feature.1'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'السبب'),
          'سبب لن يُستخدم أبدًا',
        );
        await tester.pumpAndSettle();

        // The selection changes underneath a mounted save bar — the shape a
        // hand-off from «مكاتب المنصة», or a tap on a signal row, produces.
        cubit.push(
          _state().copyWith(
            selectedOffice: OfficeLicenseDetail(
              officeId: 'office-9',
              officeName: 'مكتب آخر',
              entitlements: _detail.entitlements,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('مكتب آخر'), findsOneWidget);
        expect(
          find.textContaining('غير محفوظ'),
          findsNothing,
          reason:
              "one office's draft must never follow the operator to another",
        );
      },
    );

    testWidgets('leaving the office with unsaved changes asks first', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: board);

      await tester.tap(controlFor('feature.1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كل المكاتب'));
      await tester.pumpAndSettle();

      expect(find.text('تغييرات غير محفوظة'), findsOneWidget);
    });
  });
}
