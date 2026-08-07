import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/screens/business_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/business_attention_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/business_health_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/customer_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/financial_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/operational_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/quick_actions_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/smart_insights_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/today_kpis_section.dart';

import 'business_overview_test_fixtures.dart';

/// A cubit double that emits states directly, bypassing the twelve real use
/// cases `BusinessOverviewCubit.load()` composes. These tests are about how the
/// page renders a snapshot, not about the fetch.
class _FakeCubit extends Cubit<BusinessOverviewState>
    implements BusinessOverviewCubit {
  _FakeCubit(super.initialState);

  int loadCalls = 0;
  int refreshCalls = 0;

  @override
  Future<void> load() async => loadCalls++;

  @override
  Future<void> refresh() async => refreshCalls++;
}

const _office = OfficeContext(
  officeId: 'office-1',
  officeName: 'مكتب تجريبي',
  officeSlug: 'demo-office',
  role: DashboardRole.admin,
  username: 'demo',
  fullName: 'محمود',
  listingStatus: 'listed',
);

Widget _wrap({
  required BusinessOverviewState state,
  ValueChanged<String>? onOpenModule,
  VoidCallback? onCreateTrip,
  bool Function(String route)? canOpenRoute,
  _FakeCubit? cubit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<BusinessOverviewCubit>(
          create: (_) => cubit ?? _FakeCubit(state),
          child: BusinessOverviewScreen(
            office: _office,
            canOpenRoute: canOpenRoute ?? (_) => true,
            onOpenModule: onOpenModule,
            onCreateTrip: onCreateTrip,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the shared skeleton while loading', (tester) async {
    await tester.pumpWidget(_wrap(state: const BusinessOverviewLoading()));
    expect(find.byType(DashboardLoading), findsOneWidget);
    expect(find.byType(TodayKpisSection), findsNothing);
  });

  testWidgets('a total failure offers a retry that reloads', (tester) async {
    final cubit = _FakeCubit(const BusinessOverviewError('انقطع الاتصال'));
    await tester.pumpWidget(
      _wrap(state: const BusinessOverviewError('انقطع الاتصال'), cubit: cubit),
    );

    expect(find.text('انقطع الاتصال'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(cubit.loadCalls, 1);
  });

  testWidgets('all eight sections are present once loaded', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodayKpisSection), findsOneWidget);
    expect(find.byType(BusinessHealthSection), findsOneWidget);
    expect(find.byType(SmartInsightsSection), findsOneWidget);
    expect(find.byType(BusinessAttentionSection), findsOneWidget);
    expect(find.byType(FinancialSnapshotSection), findsOneWidget);
    expect(find.byType(OperationalSnapshotSection), findsOneWidget);
    expect(find.byType(CustomerSnapshotSection), findsOneWidget);
    expect(find.byType(QuickActionsSection), findsOneWidget);
  });

  testWidgets('the header states today\'s takings and the verdict', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(
            bookings: [buildBooking(id: 'a', amount: 1250)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('نظرة تنفيذية'), findsWidgets);
    expect(find.textContaining('1,250 ج.م'), findsWidgets);
  });

  testWidgets('a KPI tile with a measured baseline carries a trend chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(
            bookings: [
              buildBooking(id: 'today', amount: 200),
              buildBooking(id: 'yesterday', amount: 100, createdAt: daysAgo(1)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final revenueTile = tester.widget<DashboardKpiCard>(
      find.widgetWithText(DashboardKpiCard, 'إيراد الحجوزات اليوم'),
    );
    expect(revenueTile.trend, isNotNull);
    expect(revenueTile.trend!.label, '100%');
    expect(revenueTile.trend!.tone, KpiTrendTone.positive);
    expect(revenueTile.sparkline, hasLength(7));
  });

  testWidgets('headcount tiles show context instead of an invented trend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(fleet: buildFleet(activeDrivers: 6, activeVehicles: 4)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final drivers = tester.widget<DashboardKpiCard>(
      find.widgetWithText(DashboardKpiCard, 'سائقون في الخدمة'),
    );
    expect(
      drivers.trend,
      isNull,
      reason: 'no table records yesterday\'s roster, so there is no baseline',
    );
    expect(drivers.detail, contains('6'));
  });

  testWidgets('a KPI drills into the module its figure came from', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final opened = <String>[];
    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        onOpenModule: opened.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(DashboardKpiCard, 'حجوزات وردت اليوم'),
    );
    await tester.pump();
    expect(opened, [DashboardRoutes.bookings]);
  });

  testWidgets('failed feeds are named rather than shown as zero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(unavailable: {BusinessDataSource.wallet}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('لم تُحمَّل بعض المصادر'), findsOneWidget);
    expect(find.textContaining('المحافظ'), findsWidgets);
  });

  testWidgets('quick actions the operator cannot open are absent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        canOpenRoute: (route) => route != DashboardRoutes.wallet,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('منح كاش باك'), findsNothing);
    expect(find.text('تسجيل استرداد'), findsNothing);
    expect(find.text('حجز جديد'), findsOneWidget);
  });

  testWidgets('the trip planner is the one true one-click action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var planned = 0;
    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        onCreateTrip: () => planned++,
      ),
    );
    await tester.pumpAndSettle();

    // Quick actions sit at the foot of the page by design — the owner reads
    // the business before acting on it — so the tap has to scroll there first.
    // `ensureVisible`, not `scrollUntilVisible`: the ListView has already built
    // the tile below the fold, so the finder matches without it ever being on
    // screen and a scroll-until loop would exit immediately having moved
    // nothing.
    await tester.ensureVisible(find.text('رحلة جديدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رحلة جديدة'));
    await tester.pump();
    expect(planned, 1);
  });

  testWidgets('an empty console says so instead of listing empty queues', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    expect(find.text('كل شيء تحت السيطرة'), findsOneWidget);
    expect(find.text('لا توجد قراءات بارزة'), findsOneWidget);
  });

  testWidgets('refresh keeps the page and asks the cubit for fresh figures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _FakeCubit(BusinessOverviewLoaded(buildOverview()));
    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview()), cubit: cubit),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تحديث البيانات'));
    await tester.pump();

    expect(cubit.refreshCalls, 1);
    expect(find.byType(TodayKpisSection), findsOneWidget);
  });

  testWidgets('narrow windows stack without overflowing', (tester) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(
            trips: [buildTrip(id: 't1', capacity: 10, bookedSeats: 7)],
            bookings: [buildBooking(id: 'b1', amount: 500)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TodayKpisSection), findsOneWidget);
  });
}
