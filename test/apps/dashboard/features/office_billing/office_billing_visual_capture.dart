/// Visual QA harness for الباقة والفوترة — the office's own commercial screen.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/office_billing/office_billing_visual_capture.dart --update-goldens
///
/// Typesets with the **real** [DashboardAppTheme] by registering a host Arabic
/// face under the family names google_fonts asks for; without it the binding
/// draws every glyph as a box and the capture judges nothing but layout.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/domain/entities/office_invoice.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/cubit/office_billing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/screens/office_billing_screen.dart';

ResolvedFeature _limit(
  String key,
  String nameAr,
  Object value, {
  int? used,
  int? remaining,
  String meterKind = 'stock',
  String unitAr = '',
  String categoryKey = 'operations',
  int sortOrder = 10,
}) => ResolvedFeature(
  key: key,
  value: value,
  valueType: 'limit',
  source: 'plan',
  nameAr: nameAr,
  categoryKey: categoryKey,
  unitAr: unitAr,
  used: used,
  remaining: remaining,
  meterKind: meterKind,
  enforced: true,
  sortOrder: sortOrder,
);

ResolvedFeature _flag(
  String key,
  String nameAr,
  Object value, {
  String categoryKey = 'operations',
  String source = 'plan',
  String? blockedBy,
}) => ResolvedFeature(
  key: key,
  value: value,
  valueType: 'boolean',
  source: source,
  blockedBy: blockedBy,
  nameAr: nameAr,
  categoryKey: categoryKey,
  enforced: true,
);

List<ResolvedFeature> _catalog({bool held = false}) => [
  _limit(
    'max_drivers',
    'حد السائقين',
    10,
    used: 8,
    remaining: 2,
    unitAr: 'سائق',
    categoryKey: 'fleet',
  ),
  _limit(
    'max_vehicles',
    'حد المركبات',
    8,
    used: 3,
    remaining: 5,
    unitAr: 'مركبة',
    categoryKey: 'fleet',
    sortOrder: 20,
  ),
  _limit(
    'max_trips_per_month',
    'حد الرحلات شهريًا',
    100,
    used: 96,
    remaining: 4,
    meterKind: 'flow',
    unitAr: 'رحلة',
    sortOrder: 30,
  ),
  _limit(
    'max_admin_users',
    'حد مستخدمي اللوحة',
    3,
    used: 4,
    unitAr: 'مستخدم',
    categoryKey: 'platform',
    sortOrder: 40,
  ),
  _limit(
    'max_routes',
    'حد خطوط السير',
    'unlimited',
    used: 12,
    unitAr: 'خط',
    sortOrder: 50,
  ),
  _limit(
    'max_live_trips',
    'حد الرحلات الجارية',
    'unlimited',
    used: 2,
    unitAr: 'رحلة',
    sortOrder: 60,
  ),
  _flag('trips', 'الرحلات', true),
  _flag('routes', 'خطوط السير', true, categoryKey: 'operations'),
  _flag(
    'live_tracking',
    'التتبع المباشر',
    !held,
    categoryKey: 'operations',
    source: held ? 'license_hold' : 'plan',
  ),
  _flag(
    'live_ops_center',
    'مركز التشغيل المباشر',
    false,
    categoryKey: 'operations',
    blockedBy: 'live_tracking',
  ),
  _flag('drivers', 'السائقون والمركبات', true, categoryKey: 'fleet'),
  _flag('driver_app', 'تطبيق الكابتن', true, categoryKey: 'fleet'),
  _flag('bookings', 'الحجوزات', true, categoryKey: 'sales'),
  _flag('passenger_packages', 'باقات الركاب', true, categoryKey: 'sales'),
  _flag('wallet', 'محفظة العملاء', true, categoryKey: 'finance'),
  _flag(
    'cashback',
    'الكاش باك',
    false,
    categoryKey: 'finance',
    source: 'kill_switch',
  ),
  _flag(
    'refunds',
    'المرتجعات',
    !held,
    categoryKey: 'finance',
    source: held ? 'license_hold' : 'plan',
  ),
  _flag('reports', 'التقارير', true, categoryKey: 'insight'),
  _flag('export_excel', 'تصدير Excel', false, categoryKey: 'insight'),
  _flag('notifications', 'الإشعارات', true, categoryKey: 'engagement'),
  _flag('support_tickets', 'الشكاوى', true, categoryKey: 'engagement'),
];

OfficeInvoice _invoice(
  String number,
  String status, {
  num total = 1200,
  int month = 8,
}) => OfficeInvoice(
  id: 'inv-$number',
  invoiceNumber: number,
  total: total,
  status: status,
  periodStart: DateTime(2026, month, 1),
  periodEnd: DateTime(2026, month + 1, 1),
  issuedAt: DateTime(2026, month, 1),
  dueAt: DateTime(2026, month, 15),
  paidAt: status == 'paid' ? DateTime(2026, month, 9) : null,
  lineItems: const [
    {
      'type': 'plan',
      'label': 'اشتراك المنصة — باقة الأعمال',
      'qty': 1,
      'unit': 1200,
      'amount': 1200,
    },
  ],
);

void main() {
  late ThemeData light;
  late ThemeData dark;

  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      for (final family in const ['Cairo_regular', 'Cairo']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }

    await runZonedGuarded(() async {
      light = DashboardAppTheme.light();
      dark = DashboardAppTheme.dark();
    }, (_, _) {});
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('active plan, one meter under pressure — light', (tester) async {
    await _capture(
      tester,
      'office_billing_1_active_light',
      theme: light,
      state: OfficeBillingLoaded(
        entitlements: EntitlementContext(
          license: LicenseSummary(
            planKey: 'professional',
            planNameAr: 'باقة الأعمال',
            status: 'active',
            billingCycle: 'monthly',
            price: 1200,
            periodStart: DateTime(2026, 8, 1),
            periodEnd: DateTime(2026, 9, 1),
            autoRenew: true,
            contractRef: 'EWT-2026-0142',
          ),
          features: {for (final f in _catalog()) f.key: f},
          enforcementMode: 'enforcing',
          resolvedAt: DateTime(2026, 8, 30),
        ),
        invoices: [
          _invoice('INV-2026-0008', 'issued'),
          _invoice('INV-2026-0007', 'paid', month: 7),
          _invoice('INV-2026-0006', 'paid', month: 6),
        ],
        officeName: 'مكتب الميجا للنقل',
      ),
    );
  });

  testWidgets('grace period, over limit — dark', (tester) async {
    await _capture(
      tester,
      'office_billing_2_grace_dark',
      theme: dark,
      state: OfficeBillingLoaded(
        entitlements: EntitlementContext(
          license: LicenseSummary(
            planKey: 'starter',
            planNameAr: 'الباقة الأساسية',
            status: 'grace',
            billingCycle: 'monthly',
            price: 400,
            periodStart: DateTime(2026, 7, 1),
            periodEnd: DateTime(2026, 8, 1),
            graceEndsAt: DateTime.now().add(const Duration(days: 4)),
          ),
          features: {for (final f in _catalog()) f.key: f},
          enforcementMode: 'enforcing',
          resolvedAt: DateTime(2026, 8, 30),
        ),
        invoices: [
          _invoice('INV-2026-0008', 'overdue'),
          _invoice('INV-2026-0007', 'paid', month: 7),
        ],
        officeName: 'مكتب النور',
      ),
    );
  });

  testWidgets('suspended, no invoices — light', (tester) async {
    await _capture(
      tester,
      'office_billing_3_suspended_light',
      theme: light,
      state: OfficeBillingLoaded(
        entitlements: EntitlementContext(
          license: LicenseSummary(
            planKey: 'starter',
            planNameAr: 'الباقة الأساسية',
            status: 'suspended',
            billingCycle: 'monthly',
            price: 400,
            periodEnd: DateTime(2026, 7, 1),
            suspendedReason: 'عدم سداد فاتورة يوليو بعد انتهاء المهلة',
          ),
          features: {for (final f in _catalog(held: true)) f.key: f},
          enforcementMode: 'enforcing',
          resolvedAt: DateTime(2026, 8, 30),
        ),
        invoicesError: 'تعذر تحميل فواتير المكتب.',
        officeName: 'مكتب النيل',
      ),
    );
  });

  testWidgets('no licence at all, narrow window — light', (tester) async {
    await _capture(
      tester,
      'office_billing_4_none_narrow_light',
      theme: light,
      width: 820,
      state: OfficeBillingLoaded(
        entitlements: EntitlementContext(
          license: const LicenseSummary(
            planKey: 'free',
            planNameAr: '',
            status: 'none',
          ),
          features: {for (final f in _catalog()) f.key: f},
          enforcementMode: 'enforcing',
          resolvedAt: DateTime(2026, 8, 30),
        ),
        officeName: 'مكتب جديد',
      ),
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required ThemeData theme,
  required OfficeBillingLoaded state,
  double width = 1280,
  double height = 2600,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: OfficeBillingView(state: state, onRefresh: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}
