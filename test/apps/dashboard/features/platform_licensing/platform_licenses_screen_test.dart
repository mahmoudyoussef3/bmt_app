import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
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

  // The screen only reads state here; every action it can fire is a no-op.
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

Future<void> _expectNoOverflow(
  WidgetTester tester,
  PlatformLicensingLoaded state, {
  required Size size,
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
}

void main() {
  group('PlatformLicensesScreen layout', () {
    for (final size in _sizes) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with an '
          'office open', (tester) async {
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

    testWidgets('a signal shows its count, and opens onto every row', (
      tester,
    ) async {
      await _expectNoOverflow(tester, _state(), size: const Size(1680, 1050));

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
  });
}
