import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/office_license.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_billing_screen.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/widgets/audit_trail_widgets.dart';

/// سجل التغييرات has two failure modes, and the screen shipped with both.
///
///  1. **It overflowed.** A full page of rows was laid out inside a
///     viewport-height `Expanded`, so a hundred-row trail clipped by 879px and
///     the pagination bar under it could never be reached.
///  2. **It printed the database, not the decision.** `max_captains`, `true`
///     and a bare office uuid in a column called العنصر; a date with no time;
///     and the before/after values — the only reason an audit row exists —
///     loaded from the RPC and then dropped on the floor.
///
/// These tests hold both closed.

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

final _now = DateTime.now();

DateTime _at(int daysAgo, int hour) => DateTime(
  _now.year,
  _now.month,
  _now.day,
  hour,
).subtract(Duration(days: daysAgo));

const _catalog = FeatureCatalog(
  categories: [],
  features: [
    CatalogFeature(
      key: 'max_captains',
      nameAr: 'الحد الأقصى للكباتن',
      nameEn: 'Max captains',
      categoryKey: 'fleet',
      valueType: 'limit',
      defaultValue: 10,
      status: 'active',
      isEnforced: true,
    ),
    CatalogFeature(
      key: 'bookings',
      nameAr: 'حجوزات العملاء',
      nameEn: 'Bookings',
      categoryKey: 'sales',
      valueType: 'boolean',
      defaultValue: true,
      status: 'active',
      isEnforced: true,
    ),
  ],
);

const _plans = [
  LicensingPlan(
    id: 'plan-uuid-1',
    key: 'professional',
    nameAr: 'الباقة الاحترافية',
    status: 'active',
  ),
];

/// A trail with the shapes that broke the old screen: a platform-wide settings
/// row whose ref is the literal `true`, a plan-value row keyed by feature, and
/// a licence row keyed by a bare office uuid.
List<LicenseAuditEntry> _trail({int bulk = 0}) => [
  LicenseAuditEntry(
    id: 900,
    entityType: 'settings',
    entityRef: 'true',
    action: 'updated',
    createdAt: _at(0, 14),
    actorLabel: 'محمود',
    oldValue: const {'enforcement_mode': 'shadow', 'updated_at': 'a'},
    newValue: const {'enforcement_mode': 'enforcing', 'updated_at': 'b'},
  ),
  LicenseAuditEntry(
    id: 899,
    entityType: 'plan_feature',
    entityRef: 'max_captains',
    action: 'limit_changed',
    createdAt: _at(0, 11),
    actorLabel: 'النظام',
    oldValue: const {'plan_id': 'plan-uuid-1', 'value': 20},
    newValue: const {'plan_id': 'plan-uuid-1', 'value': 40},
  ),
  LicenseAuditEntry(
    id: 898,
    entityType: 'license',
    entityRef: '6f1c9c2e-1111-4222-8333-444455556666',
    action: 'suspended',
    createdAt: _at(1, 9),
    officeName: 'مكتب النقل السريع',
    actorLabel: 'محمود',
    reason: 'توقف السداد لشهرين متتاليين',
    oldValue: const {'status': 'active'},
    newValue: const {'status': 'suspended'},
  ),
  for (var i = 0; i < bulk; i++)
    LicenseAuditEntry(
      id: i,
      entityType: 'feature',
      entityRef: 'bookings',
      action: 'updated',
      createdAt: _at(2 + (i % 5), 8),
      actorLabel: 'النظام',
    ),
];

PlatformLicensingLoaded _state({int bulk = 0}) => PlatformLicensingLoaded(
  catalog: _catalog,
  plans: _plans,
  audit: _trail(bulk: bulk),
);

Future<void> _pump(
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
          child: const Scaffold(body: PlatformBillingScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // «الفوترة والسجل» opens on the invoice ledger. Every test in this file is
  // about the audit trail, which is the destination's second section.
  await tester.tap(find.text('سجل التغييرات'));
  await tester.pumpAndSettle();
}

void main() {
  group('PlatformBillingScreen layout', () {
    for (final size in _sizes) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} with a '
          'full page of rows', (tester) async {
        // 97 + 3 rows: the read cap, which is exactly what overflowed before.
        await _pump(tester, _state(bulk: 97), size: size);

        // An overflowing Row/Column throws during paint in debug builds and the
        // binding captures it, so a null exception here is a genuine assertion.
        expect(
          tester.takeException(),
          isNull,
          reason: 'سجل التغييرات overflowed at ${size.width}×${size.height}',
        );
      });
    }
  });

  group('PlatformBillingScreen reads as decisions', () {
    testWidgets('resolves machine references to the catalog vocabulary', (
      tester,
    ) async {
      await _pump(tester, _state());

      // `true`, `max_captains` and a bare uuid used to be printed raw.
      expect(find.text('true'), findsNothing);
      expect(find.text('max_captains'), findsNothing);
      expect(find.textContaining('6f1c9c2e'), findsNothing);

      expect(find.text('إعدادات المنصة'), findsOneWidget);
      expect(
        find.text('الحد الأقصى للكباتن — باقة الباقة الاحترافية'),
        findsOneWidget,
      );
      expect(find.text('مكتب النقل السريع'), findsWidgets);
    });

    testWidgets('shows the time and groups the trail by day', (tester) async {
      await _pump(tester, _state());

      expect(find.text('14:00'), findsOneWidget);
      // Scoped to the day separators: "اليوم" is also a period filter.
      final days = find.byType(AuditDayHeader);
      expect(find.descendant(of: days, matching: find.text('اليوم')), findsOne);
      expect(find.descendant(of: days, matching: find.text('أمس')), findsOne);
      expect(find.text('2 تغيير'), findsOneWidget);
    });

    testWidgets('opens the before → after values a row is kept for', (
      tester,
    ) async {
      await _pump(tester, _state());

      // Collapsed: the detail is not built at all.
      expect(find.text('الحالة'), findsNothing);

      await tester.tap(find.byType(AuditEntryTile).at(2));
      await tester.pumpAndSettle();

      expect(find.text('الحالة'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('موقوف'), findsOneWidget);
      // The raw row stays reachable for an auditor, out of the reading line.
      expect(find.text('رقم السجل: #898', findRichText: true), findsOneWidget);
      expect(
        find.text(
          'المرجع: 6f1c9c2e-1111-4222-8333-444455556666',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('states the read cap instead of implying it is everything', (
      tester,
    ) async {
      await _pump(tester, _state(bulk: 97));

      expect(find.textContaining('عرض 70 تغييرًا أقدم'), findsOneWidget);
      expect(find.text('المعروض 30 من 100'), findsOneWidget);

      final more = find.textContaining('عرض 70 تغييرًا أقدم');
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('المعروض 60 من 100'), findsOneWidget);
    });

    testWidgets('searching narrows the trail without hiding that it did', (
      tester,
    ) async {
      await _pump(tester, _state(bulk: 20));

      await tester.enterText(find.byType(TextField), 'السداد');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('المعروض 1 من 1'), findsOneWidget);
      expect(find.text('إعدادات المنصة'), findsNothing);
    });
  });
}
