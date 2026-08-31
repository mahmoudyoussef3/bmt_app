import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/domain/entities/office_invoice.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/cubit/office_billing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/models/office_invoice_view.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/models/office_license_view.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/screens/office_billing_screen.dart';
import 'package:bmt_app/apps/dashboard/features/office_billing/presentation/widgets/office_upgrade_request_dialog.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// الباقة والفوترة, at the UI.
///
/// The screen this replaces drew one identical progress bar per limit feature —
/// ten of them reading «بلا حدود» over a track that could never move, two
/// reading «0 / 0» because they were internal catalogue rows — and told an
/// office with no licence at all nothing whatsoever. These assertions are about
/// the facts the resolver has always carried and the office was never shown.

ResolvedFeature _limit(
  String key, {
  required String nameAr,
  required Object value,
  int? used,
  int? remaining,
  String meterKind = 'stock',
  String unitAr = '',
  bool isPublic = true,
  bool enforced = true,
  int sortOrder = 10,
}) => ResolvedFeature(
  key: key,
  value: value,
  valueType: 'limit',
  source: 'plan',
  nameAr: nameAr,
  categoryKey: 'operations',
  unitAr: unitAr,
  used: used,
  remaining: remaining,
  meterKind: meterKind,
  isPublic: isPublic,
  enforced: enforced,
  sortOrder: sortOrder,
);

ResolvedFeature _flag(
  String key, {
  required String nameAr,
  required Object value,
  String source = 'plan',
  String? blockedBy,
  String categoryKey = 'operations',
  bool isPublic = true,
  bool enforced = true,
}) => ResolvedFeature(
  key: key,
  value: value,
  valueType: 'boolean',
  source: source,
  blockedBy: blockedBy,
  nameAr: nameAr,
  categoryKey: categoryKey,
  isPublic: isPublic,
  enforced: enforced,
);

EntitlementContext _context({
  LicenseSummary? license,
  List<ResolvedFeature> features = const [],
  String enforcementMode = 'enforcing',
}) => EntitlementContext(
  license:
      license ??
      LicenseSummary(
        planKey: 'professional',
        planNameAr: 'باقة الأعمال',
        status: 'active',
        billingCycle: 'monthly',
        price: 1200,
        periodStart: DateTime(2026, 8, 1),
        periodEnd: DateTime(2026, 9, 1),
        autoRenew: true,
      ),
  features: {for (final f in features) f.key: f},
  enforcementMode: enforcementMode,
  resolvedAt: DateTime(2026, 8, 30),
);

OfficeInvoice _invoice({
  required String number,
  required String status,
  num total = 1200,
  DateTime? dueAt,
  List<Map<String, dynamic>> lineItems = const [],
}) => OfficeInvoice(
  id: 'inv-$number',
  invoiceNumber: number,
  total: total,
  status: status,
  periodStart: DateTime(2026, 8, 1),
  periodEnd: DateTime(2026, 9, 1),
  issuedAt: DateTime(2026, 8, 1),
  dueAt: dueAt ?? DateTime(2026, 8, 15),
  lineItems: lineItems,
);

Future<void> _pump(
  WidgetTester tester,
  OfficeBillingLoaded state, {
  double textScale = 1.0,
  Size size = const Size(1280, 3600),
  VoidCallback? onRetryInvoices,
}) async {
  // The screen is one long ListView, and a sliver builds only what the viewport
  // reaches — at the 800×600 default the invoice table below the fold does not
  // exist to be asserted on.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: OfficeBillingView(
                state: state,
                onRetryInvoices: onRetryInvoices,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The fold store is process-wide, so one test opening a panel would otherwise
  // decide what the next one sees.
  setUp(DashboardSectionStateStore.instance.clear);

  group('حالة الاشتراك', () {
    testWidgets('names the plan, its price and the next date without a fold', (
      tester,
    ) async {
      await _pump(tester, OfficeBillingLoaded(entitlements: _context()));

      expect(find.text('باقة الأعمال'), findsOneWidget);
      expect(find.text('1200 ج.م · شهريًا'), findsOneWidget);
      expect(find.text('التجديد التالي'), findsOneWidget);
      expect(find.text('2026-09-01'), findsWidgets);
      expect(find.text('نشطة'), findsOneWidget);
    });

    testWidgets('an office with no licence is told so, loudly', (tester) async {
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(
            license: const LicenseSummary(
              planKey: '',
              planNameAr: '',
              status: 'none',
            ),
          ),
        ),
      );

      expect(find.text('بدون ترخيص'), findsOneWidget);
      expect(find.text('لا توجد باقة مرتبطة بمكتبك بعد.'), findsOneWidget);
      expect(find.text('بدون باقة'), findsOneWidget);
    });

    testWidgets('a held licence shows its reason and what still works', (
      tester,
    ) async {
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(
            license: LicenseSummary(
              planKey: 'starter',
              planNameAr: 'الباقة الأساسية',
              status: 'suspended',
              periodEnd: DateTime(2026, 7, 1),
              suspendedReason: 'فاتورة يوليو غير مسددة',
            ),
          ),
        ),
      );

      expect(find.text('الحساب في وضع القراءة فقط.'), findsOneWidget);
      expect(find.textContaining('فاتورة يوليو غير مسددة'), findsOneWidget);
      expect(
        find.textContaining('التذاكر المُباعة والرحلات الجارية'),
        findsWidgets,
      );
    });

    testWidgets('grace renders the grace date, not the period end', (
      tester,
    ) async {
      // Whole days, counted down: `inDays` truncates, so three days minus the
      // microseconds this test takes to run would read as two.
      final graceEnd = DateTime.now().add(const Duration(days: 3, hours: 1));
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(
            license: LicenseSummary(
              planKey: 'starter',
              planNameAr: 'الباقة الأساسية',
              status: 'grace',
              periodEnd: DateTime(2026, 7, 1),
              graceEndsAt: graceEnd,
            ),
          ),
        ),
      );

      expect(find.text('تنتهي المهلة'), findsOneWidget);
      expect(find.text('باقٍ 3 يوم'), findsOneWidget);
    });
  });

  group('الاستخدام والحدود', () {
    OfficeBillingLoaded loaded({String enforcementMode = 'enforcing'}) =>
        OfficeBillingLoaded(
          entitlements: _context(
            enforcementMode: enforcementMode,
            features: [
              _limit(
                'max_drivers',
                nameAr: 'حد السائقين',
                value: 10,
                used: 12,
                unitAr: 'سائق',
              ),
              _limit(
                'max_trips_per_month',
                nameAr: 'حد الرحلات شهريًا',
                value: 100,
                used: 40,
                remaining: 60,
                meterKind: 'flow',
                unitAr: 'رحلة',
                sortOrder: 20,
              ),
              _limit(
                'max_routes',
                nameAr: 'حد خطوط السير',
                value: 'unlimited',
                used: 8,
                unitAr: 'خط',
                sortOrder: 30,
              ),
              // Internal catalogue rows: not public, nothing enforcing them.
              // These are the «0 / 0 فرع» meters the old panel drew.
              _limit(
                'max_branches',
                nameAr: 'حد الفروع',
                value: 0,
                used: 0,
                unitAr: 'فرع',
                isPublic: false,
                enforced: false,
                sortOrder: 40,
              ),
            ],
          ),
        );

    testWidgets('draws a bar only for a limit that can actually move', (
      tester,
    ) async {
      await _pump(tester, loaded());

      // Two capped meters — not one bar per limit feature.
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(find.text('12 / 10 سائق'), findsOneWidget);
      expect(find.text('40 / 100 رحلة'), findsOneWidget);
    });

    testWidgets('an unlimited meter is a chip with its count, not a bar', (
      tester,
    ) async {
      await _pump(tester, loaded());

      expect(find.text('بلا حدود في باقتك'), findsOneWidget);
      expect(find.text('حد خطوط السير · 8 خط'), findsOneWidget);
    });

    testWidgets('internal, unenforced meters never reach the office', (
      tester,
    ) async {
      await _pump(tester, loaded());

      expect(find.text('حد الفروع'), findsNothing);
    });

    testWidgets('over-limit names the metric and states what it blocks', (
      tester,
    ) async {
      await _pump(tester, loaded());

      expect(find.text('تجاوزت «حد السائقين»'), findsOneWidget);
      expect(find.text('تجاوزت الحد بمقدار 2 سائق'), findsOneWidget);
      expect(
        find.textContaining('لم يُحذف ولم يُعطَّل أي عنصر قائم'),
        findsWidgets,
      );
    });

    testWidgets('a flow meter says it counts the month', (tester) async {
      await _pump(tester, loaded());

      expect(find.text('هذا الشهر'), findsOneWidget);
      expect(find.text('العدد الحالي'), findsOneWidget);
      expect(find.text('متبقٍ 60 رحلة'), findsOneWidget);
    });

    testWidgets('while the platform is not enforcing, it says so', (
      tester,
    ) async {
      await _pump(tester, loaded(enforcementMode: 'shadow'));

      expect(find.text('الحدود غير مُطبَّقة حاليًا'), findsOneWidget);
    });
  });

  group('ما تشمله باقتك', () {
    testWidgets('an off feature names its own reason', (tester) async {
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(
            features: [
              _flag('trips', nameAr: 'الرحلات', value: true),
              _flag('live_tracking', nameAr: 'التتبع المباشر', value: false),
              _flag(
                'cashback',
                nameAr: 'الكاش باك',
                value: false,
                categoryKey: 'finance',
                blockedBy: 'wallet',
              ),
              _flag(
                'reports',
                nameAr: 'التقارير',
                value: false,
                categoryKey: 'insight',
                source: 'kill_switch',
              ),
              _flag(
                'refunds',
                nameAr: 'المرتجعات',
                value: false,
                categoryKey: 'finance',
                source: 'license_hold',
              ),
              _flag(
                'wallet',
                nameAr: 'محفظة العملاء',
                value: true,
                categoryKey: 'finance',
              ),
            ],
          ),
        ),
      );

      expect(find.text('غير مشمولة في باقتك الحالية'), findsOneWidget);
      // The prerequisite is named, not keyed.
      expect(find.text('تتطلب تفعيل «محفظة العملاء» أولًا'), findsOneWidget);
      expect(
        find.text('موقوفة على مستوى المنصة مؤقتًا — لا علاقة لها بباقتك'),
        findsOneWidget,
      );
      expect(
        find.text('معلّقة بسبب حالة اشتراكك — تعود بمجرد عودة الترخيص'),
        findsOneWidget,
      );
    });

    testWidgets('a declared feature is never offered as an upgrade', (
      tester,
    ) async {
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(
            features: [
              _flag(
                'white_label',
                nameAr: 'العلامة البيضاء',
                value: false,
                categoryKey: 'platform',
                isPublic: false,
                enforced: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('العلامة البيضاء'), findsNothing);
    });
  });

  group('الفواتير', () {
    final invoices = [
      _invoice(number: 'INV-001', status: 'overdue'),
      _invoice(number: 'INV-002', status: 'paid'),
      _invoice(
        number: 'INV-003',
        status: 'issued',
        lineItems: const [
          {
            'type': 'plan',
            'label': 'اشتراك المنصة',
            'qty': 1,
            'unit': 1200,
            'amount': 1200,
          },
        ],
      ),
    ];

    testWidgets('renders as a table and filters by queue tab', (tester) async {
      await _pump(
        tester,
        OfficeBillingLoaded(entitlements: _context(), invoices: invoices),
      );

      expect(find.text('INV-001'), findsOneWidget);
      expect(find.text('INV-002'), findsOneWidget);

      await tester.tap(find.text('مسدَّدة'));
      await tester.pumpAndSettle();

      expect(find.text('INV-002'), findsOneWidget);
      expect(find.text('INV-001'), findsNothing);
    });

    testWidgets('a row opens the invoice and renders its line items', (
      tester,
    ) async {
      await _pump(
        tester,
        OfficeBillingLoaded(entitlements: _context(), invoices: invoices),
      );

      await tester.tap(find.text('INV-003'));
      await tester.pumpAndSettle();

      expect(find.text('البنود'), findsOneWidget);
      expect(find.text('اشتراك المنصة'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
    });

    testWidgets('a failed invoice read never takes the plan down with it', (
      tester,
    ) async {
      var retried = 0;
      await _pump(
        tester,
        OfficeBillingLoaded(
          entitlements: _context(),
          invoicesError: 'تعذر تحميل فواتير المكتب.',
        ),
        onRetryInvoices: () => retried++,
      );

      // The plan is still on screen.
      expect(find.text('باقة الأعمال'), findsOneWidget);
      expect(find.text('تعذر تحميل فواتير المكتب.'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(retried, 1);
    });

    testWidgets('an office with no invoices is told, not left blank', (
      tester,
    ) async {
      await _pump(tester, OfficeBillingLoaded(entitlements: _context()));

      expect(find.text('لا توجد فواتير'), findsOneWidget);
    });
  });

  group('paging', () {
    test('a filter that shortens the list cannot strand the pager', () {
      final rows = [
        for (var i = 0; i < 3; i++) _invoice(number: 'INV-$i', status: 'paid'),
      ];

      expect(officeInvoicePageCount(rows.length), 1);
      expect(officeInvoicePage(rows, 1), isEmpty);
      expect(officeInvoicePage(rows, 0), hasLength(3));
    });
  });

  group('the contact request', () {
    test('carries the office, the plan and the meter under pressure', () {
      final body = composeUpgradeRequest(
        license: LicenseSummary(
          planKey: 'starter',
          planNameAr: 'الباقة الأساسية',
          status: 'active',
          billingCycle: 'monthly',
          price: 400,
          periodEnd: DateTime(2026, 9, 1),
        ),
        officeName: 'مكتب الميجا للنقل',
        pressuredMeters: [
          _limit(
            'max_drivers',
            nameAr: 'حد السائقين',
            value: 10,
            used: 12,
            unitAr: 'سائق',
          ),
        ],
      );

      expect(body, contains('مكتب الميجا للنقل'));
      expect(body, contains('الباقة الأساسية'));
      expect(body, contains('حد السائقين — 12 / 10 سائق'));
      expect(body, contains('نهاية الفترة الحالية: 2026-09-01'));
    });
  });

  group('the status view', () {
    test('every status has a tone, a sentence and a deadline label', () {
      const statuses = [
        'trialing',
        'active',
        'past_due',
        'grace',
        'suspended',
        'cancelled',
        'expired',
        'none',
      ];

      for (final status in statuses) {
        final view = LicenseStatusView.of(
          LicenseSummary(planKey: 'p', planNameAr: 'باقة', status: status),
        );
        expect(view.headline, isNotEmpty, reason: status);
        expect(view.statusLabel, isNotEmpty, reason: status);
      }

      expect(
        LicenseStatusView.of(
          const LicenseSummary(planKey: 'p', planNameAr: 'ب', status: 'active'),
        ).tone,
        AppStatusTone.success,
      );
      expect(
        LicenseStatusView.of(
          const LicenseSummary(
            planKey: 'p',
            planNameAr: 'ب',
            status: 'suspended',
          ),
        ).isRestricted,
        isTrue,
      );
    });
  });

  testWidgets('the screen survives 1.6× text scale without overflowing', (
    tester,
  ) async {
    await _pump(
      tester,
      OfficeBillingLoaded(
        entitlements: _context(
          features: [
            _limit(
              'max_drivers',
              nameAr: 'حد السائقين',
              value: 10,
              used: 9,
              unitAr: 'سائق',
            ),
            _flag('trips', nameAr: 'الرحلات', value: true),
            _flag('live_tracking', nameAr: 'التتبع المباشر', value: false),
          ],
        ),
        invoices: [_invoice(number: 'INV-001', status: 'issued')],
        officeName: 'مكتب الميجا للنقل',
      ),
      textScale: 1.6,
      size: const Size(1100, 4200),
    );

    expect(tester.takeException(), isNull);
  });
}
