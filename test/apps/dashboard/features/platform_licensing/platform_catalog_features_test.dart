import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/licensing_catalog.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/entities/office_license.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/repositories/platform_licensing_repository.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/domain/usecases/platform_licensing_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/screens/platform_catalog_screen.dart';

/// Widths the console is actually used at: the tablet split point, and a wide
/// desktop workspace where the list and detail sit side by side.
const _widths = <double>[900, 1280, 1600];

const _categories = [
  FeatureCategory(key: 'money', nameAr: 'المالية', sortOrder: 1),
  FeatureCategory(key: 'comms', nameAr: 'التواصل والدعم', sortOrder: 2),
];

final _catalog = FeatureCatalog(
  categories: _categories,
  features: [
    const CatalogFeature(
      key: 'notifications',
      nameAr: 'التنبيهات',
      nameEn: 'Notifications',
      categoryKey: 'comms',
      valueType: 'boolean',
      defaultValue: true,
      status: 'active',
      isEnforced: true,
      descriptionAr: 'إشعارات التشغيل للعملاء والكباتن.',
      gates: [
        FeatureGate(
          kind: 'trigger',
          ref: 'notify_on_booking',
          note: 'يُطلق عند كل حجز',
        ),
      ],
      planCount: 3,
      overrideCount: 1,
      impact: {'true': 4, 'false': 1},
    ),
    const CatalogFeature(
      key: 'marketing',
      nameAr: 'أدوات التسويق',
      nameEn: 'Marketing tools',
      categoryKey: 'comms',
      valueType: 'boolean',
      defaultValue: false,
      status: 'active',
      // The catalog's whole reason for existing: listed, sellable, and with no
      // code behind it.
      isEnforced: false,
      sortOrder: 20,
    ),
    const CatalogFeature(
      key: 'wallet',
      nameAr: 'محفظة العملاء',
      nameEn: 'Customer wallet',
      categoryKey: 'money',
      valueType: 'limit',
      defaultValue: 50,
      unitAr: 'عملية',
      status: 'active',
      isEnforced: true,
      meterKind: 'flow',
      requires: ['finance'],
      requiredBy: ['refunds'],
    ),
  ],
);

/// Only the calls this screen makes are answered; anything else throws through
/// `noSuchMethod`, so a screen that quietly grew a new dependency fails loudly.
class _FakeRepo implements PlatformLicensingRepository {
  final statusCalls = <List<String>>[];

  @override
  Future<FeatureCatalog> catalog() async => _catalog;

  @override
  Future<void> setFeatureStatus(String key, String status) async {
    statusCalls.add([key, status]);
  }

  @override
  Future<List<LicensingPlan>> plans() async => const [];

  @override
  Future<List<OfficeLicenseRow>> licenses() async => const [];

  @override
  Future<LicensingSettings> settings() async =>
      const LicensingSettings(enforcementMode: 'enforcing');

  @override
  Future<LicensingHealth> health() async => LicensingHealth.empty;

  @override
  Future<List<OfficeUsageRow>> usage() async => const [];

  @override
  Future<List<LicenseAuditEntry>> audit({
    Map<String, dynamic> filters = const {},
    int limit = 100,
    int offset = 0,
  }) async => const [];

  @override
  Future<BillingOverview> billing({String? officeId, String? status}) async =>
      BillingOverview.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlatformLicensingCubit _cubit(PlatformLicensingRepository repo) =>
    PlatformLicensingCubit(
      getCatalog: GetFeatureCatalogUseCase(repo),
      setFeatureStatus: SetFeatureStatusUseCase(repo),
      getPlans: GetPlansUseCase(repo),
      getPlanDetail: GetPlanDetailUseCase(repo),
      savePlan: SavePlanUseCase(repo),
      clonePlan: ClonePlanUseCase(repo),
      previewPlan: PreviewPlanUseCase(repo),
      getLicenses: GetOfficeLicensesUseCase(repo),
      getLicense: GetOfficeLicenseUseCase(repo),
      assignPlan: AssignPlanUseCase(repo),
      setLicenseStatus: SetLicenseStatusUseCase(repo),
      extendTrial: ExtendTrialUseCase(repo),
      setOverride: SetFeatureOverrideUseCase(repo),
      clearOverride: ClearFeatureOverrideUseCase(repo),
      getBilling: GetBillingOverviewUseCase(repo),
      issueInvoice: IssueInvoiceUseCase(repo),
      recordPayment: RecordInvoicePaymentUseCase(repo),
      voidInvoice: VoidInvoiceUseCase(repo),
      getUsage: GetPlatformUsageUseCase(repo),
      getAudit: GetLicenseAuditUseCase(repo),
      getHealth: GetLicensingHealthUseCase(repo),
      getSettings: GetLicensingSettingsUseCase(repo),
      updateSettings: UpdateLicensingSettingsUseCase(repo),
      runLifecycle: RunLicensingLifecycleUseCase(repo),
      runBillingCycle: RunBillingCycleUseCase(repo),
    );

Future<_FakeRepo> _pump(WidgetTester tester, {double width = 1600}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = _FakeRepo();
  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider(
          // The shell creates every module's cubit with load() already applied.
          create: (_) => _cubit(repo)..load(),
          child: const Scaffold(body: PlatformCatalogScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // «الباقات والميزات» opens on the plans gallery. Every test in this file is
  // about the feature catalog, which is the destination's second section.
  await tester.tap(find.text('الميزات'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('groups the catalog by category instead of repeating it per row', (
    tester,
  ) async {
    await _pump(tester);

    // The category appears once, as a group header — not once per row, which is
    // what the unlabelled column layout used to do.
    expect(find.text('التواصل والدعم'), findsOneWidget);
    expect(find.text('المالية'), findsOneWidget);
    expect(find.text('التنبيهات'), findsOneWidget);
    expect(find.text('محفظة العملاء'), findsOneWidget);
  });

  testWidgets('a feature with no code behind it is marked on its row', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('معلنة فقط'), findsWidgets);
    expect(find.text('2'), findsWidgets); // the comms group's count
  });

  testWidgets('the "معلنة فقط" segment filters the list to what it counts', (
    tester,
  ) async {
    await _pump(tester);

    // The toolbar's enforcement switch carries its own count, so the control
    // and the number it filters to are the same thing.
    await tester.tap(find.text('معلنة فقط (1)'));
    await tester.pumpAndSettle();

    expect(find.text('أدوات التسويق'), findsOneWidget);
    expect(find.text('التنبيهات'), findsNothing);
    // And says outright that what is on screen is not the whole catalog.
    expect(find.text('1 من 3'), findsOneWidget);
  });

  testWidgets('search narrows the list, and clearing restores it', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'wallet');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('محفظة العملاء'), findsOneWidget);
    expect(find.text('التنبيهات'), findsNothing);

    await tester.tap(find.text('مسح التصفية').first);
    await tester.pumpAndSettle();

    expect(find.text('التنبيهات'), findsOneWidget);
    expect(find.text('3 ميزة'), findsOneWidget);
  });

  testWidgets('selecting a row answers the catalog\'s questions, labelled', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('محفظة العملاء'));
    await tester.pumpAndSettle();

    // Every value the old row showed in an unnamed column now carries its name.
    expect(find.text('القيمة الافتراضية'), findsOneWidget);
    expect(find.text('50 عملية'), findsOneWidget);
    expect(find.text('نوع العدّاد'), findsOneWidget);
    expect(find.text('تدفّق — الحذف لا يعيد الحصة'), findsOneWidget);
  });

  testWidgets('a declared feature says so where it would be enforced', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('أدوات التسويق'));
    await tester.pumpAndSettle();

    expect(find.text('أين تُطبَّق وما تتطلبه'), findsOneWidget);
    expect(
      find.textContaining('لا يوجد كود يطبّق هذه الميزة بعد'),
      findsOneWidget,
    );
  });

  testWidgets('the platform kill switch asks before it fires', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('أدوات التسويق'));
    await tester.pumpAndSettle();

    final detail = find.byKey(const PageStorageKey('feature-detail-marketing'));
    await tester.dragUntilVisible(
      find.text('حالة الميزة'),
      detail,
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'موقوفة'));
    await tester.pumpAndSettle();

    expect(find.text('إيقاف الميزة على مستوى المنصة'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(repo.statusCalls, isEmpty, reason: 'cancelling must not fire it');

    await tester.tap(find.widgetWithText(ChoiceChip, 'موقوفة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إيقاف الميزة'));
    await tester.pumpAndSettle();

    expect(repo.statusCalls, [
      ['marketing', 'disabled'],
    ]);
  });

  for (final width in _widths) {
    testWidgets('lays out without overflow @ ${width}px', (tester) async {
      await _pump(tester, width: width);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('التنبيهات'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
