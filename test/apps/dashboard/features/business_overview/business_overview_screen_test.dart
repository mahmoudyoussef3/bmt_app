import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/models/overview_window.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/screens/business_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/business_attention_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/business_health_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/customer_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/financial_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/operational_snapshot_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/overview_kit.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/period_kpi_band.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/quick_actions_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/route_performance_section.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/widgets/smart_insights_section.dart';

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
  OverviewWindow initialWindow = OverviewWindow.month,
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
            initialWindow: initialWindow,
          ),
        ),
      ),
    ),
  );
}

/// A console-sized window, wide enough for the two-column layout.
void _desktop(WidgetTester tester, {Size size = const Size(1600, 2600)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Scrolls the page until [finder] has been built and is on screen.
///
/// The page is a lazy `ListView`, so a panel below the viewport is not merely
/// off screen — it has not been built, and a plain `ensureVisible` throws
/// "No element".
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    360,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  // Fold state is process-wide by design, so one test collapsing a section
  // would otherwise hide it from the next.
  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('renders the shared skeleton while loading', (tester) async {
    await tester.pumpWidget(_wrap(state: const BusinessOverviewLoading()));
    expect(find.byType(DashboardLoading), findsOneWidget);
    expect(find.byType(PeriodKpiBand), findsNothing);
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

  testWidgets('every panel is present once loaded', (tester) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PeriodKpiBand), findsOneWidget);
    expect(find.byType(BusinessAttentionSection), findsOneWidget);
    expect(find.byType(BusinessHealthSection), findsOneWidget);
    expect(find.byType(FinancialSnapshotSection), findsOneWidget);
    expect(find.byType(RoutePerformanceSection), findsOneWidget);
    expect(find.byType(OperationalSnapshotSection), findsOneWidget);
    expect(find.byType(CustomerSnapshotSection), findsOneWidget);
    expect(find.byType(SmartInsightsSection), findsOneWidget);
    expect(find.byType(QuickActionsSection), findsOneWidget);
  });

  testWidgets('the title block states the office, the period and the verdict', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(bookings: [buildBooking(id: 'a', amount: 1250)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A bare title block, styled as الرئيسية's — not a gradient hero.
    expect(find.text('نظرة تنفيذية'), findsOneWidget);
    expect(find.textContaining('مكتب تجريبي'), findsWidgets);
    expect(find.textContaining('آخر ٣٠ يوماً'), findsWidgets);
    expect(find.textContaining('بانتظار قرارك'), findsWidgets);
    // The money leads the KPI band, where Home keeps it.
    expect(
      find.widgetWithText(DashboardKpiCard, 'إيراد الفترة'),
      findsOneWidget,
    );
    expect(find.textContaining('1,250 ج.م'), findsWidgets);
  });

  testWidgets('a measured baseline earns a movement chip, and only then', (
    tester,
  ) async {
    _desktop(tester);

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

    // Today's takings doubled against yesterday's, which is a real baseline.
    expect(find.text('100%'), findsWidgets);

    // The window trend has no baseline: the office's first booking postdates
    // the previous 30 days, so the tile shows its value with no arrow rather
    // than reporting a business that appeared out of nowhere.
    final bookingsTile = tester.widget<DashboardKpiCard>(
      find.widgetWithText(DashboardKpiCard, 'حجوزات الفترة'),
    );
    expect(bookingsTile.trend, isNull);
    expect(bookingsTile.sparkline, hasLength(OverviewWindow.month.days));
  });

  testWidgets('headcounts live in the operational panel with context, not a '
      'trend', (tester) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(fleet: buildFleet(activeDrivers: 6, activeVehicles: 4)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Not a headline KPI: no table records yesterday's roster, so it has no
    // baseline and does not belong beside four tiles that do.
    expect(
      find.widgetWithText(DashboardKpiCard, 'سائقون في الخدمة'),
      findsNothing,
    );

    final drivers = tester.widget<OverviewCell>(
      find.widgetWithText(OverviewCell, 'سائقون في الخدمة'),
    );
    expect(drivers.note, contains('6'));
  });

  testWidgets('a KPI drills into the module its figure came from', (
    tester,
  ) async {
    _desktop(tester);

    final opened = <String>[];
    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        onOpenModule: opened.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DashboardKpiCard, 'حجوزات الفترة'));
    await tester.pump();
    expect(opened, [DashboardRoutes.bookings]);
  });

  testWidgets('the period control re-scopes every time-based figure', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('آخر ٣٠ يوماً'), findsWidgets);
    expect(find.textContaining('آخر ٧ أيام'), findsNothing);

    await tester.tap(find.text('٧ أيام'));
    await tester.pumpAndSettle();

    expect(find.textContaining('آخر ٧ أيام'), findsWidgets);

    // Live state keeps its own label and does not follow the period.
    expect(
      find.text('اليوم — أرقام لحظية لا تتبع الفترة المختارة'),
      findsOneWidget,
    );
  });

  testWidgets('failed feeds are named rather than shown as zero', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(unavailable: {BusinessDataSource.wallet}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The shared notice every other module shows for a partial load.
    expect(find.textContaining('تعذّر تحميل:'), findsOneWidget);
    expect(find.textContaining('المحافظ'), findsWidgets);
  });

  testWidgets('quick actions the operator cannot open are absent', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        canOpenRoute: (route) => route != DashboardRoutes.wallet,
      ),
    );
    await tester.pumpAndSettle();

    await _reveal(tester, find.text('حجز جديد'));

    expect(find.text('منح كاش باك'), findsNothing);
    expect(find.text('تسجيل استرداد'), findsNothing);
    expect(find.text('حجز جديد'), findsOneWidget);
  });

  testWidgets('the trip planner is the one true one-click action, and it is '
      'in the hero', (tester) async {
    _desktop(tester);

    var planned = 0;
    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(buildOverview()),
        onCreateTrip: () => planned++,
      ),
    );
    await tester.pumpAndSettle();

    // No scrolling: it sits in the brand band, not at the foot of the page
    // where it used to be, and it is not repeated in «إجراءات سريعة».
    expect(find.text('رحلة جديدة'), findsOneWidget);
    await tester.tap(find.text('رحلة جديدة'));
    await tester.pump();
    expect(planned, 1);
  });

  testWidgets('an empty console says so instead of listing empty queues', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    expect(find.text('كل شيء تحت السيطرة'), findsOneWidget);
    expect(find.text('لا توجد قراءات بارزة'), findsOneWidget);
    expect(find.text('لا بيانات إشغال بعد'), findsOneWidget);
  });

  testWidgets('routes are ranked by how full they ran', (tester) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(
            trips: [
              buildTrip(
                id: 'full',
                route: 'طنطا - القاهرة',
                capacity: 10,
                bookedSeats: 9,
                at: daysAgo(2),
              ),
              buildTrip(
                id: 'empty',
                route: 'أسيوط - القاهرة',
                capacity: 10,
                bookedSeats: 2,
                at: daysAgo(3),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _reveal(tester, find.byType(RoutePerformanceSection));
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);

    final best = tester.getTopLeft(find.text('طنطا - القاهرة'));
    final worst = tester.getTopLeft(find.text('أسيوط - القاهرة'));
    expect(best.dy, lessThan(worst.dy));
  });

  testWidgets('refresh keeps the page and asks the cubit for fresh figures', (
    tester,
  ) async {
    _desktop(tester);

    final cubit = _FakeCubit(BusinessOverviewLoaded(buildOverview()));
    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview()), cubit: cubit),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'تحديث'));
    await tester.pump();

    expect(cubit.refreshCalls, 1);
    expect(find.byType(PeriodKpiBand), findsOneWidget);
  });

  testWidgets('a figure derived from a missing feed is a dash, not a zero', (
    tester,
  ) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(
        state: BusinessOverviewLoaded(
          buildOverview(
            bookings: [buildBooking(id: 'a', amount: 400)],
            unavailable: {BusinessDataSource.wallet},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _reveal(tester, find.byType(FinancialSnapshotSection));

    // `refundsSettled` reports 0 with no wallet, so printing net revenue here
    // would assert that nothing was refunded.
    final net = tester.widget<OverviewFigure>(
      find.widgetWithText(OverviewFigure, 'بعد المستردات'),
    );
    expect(net.value, '—');

    final gross = tester.widget<OverviewFigure>(
      find.widgetWithText(OverviewFigure, 'المحصّل'),
    );
    expect(gross.value, '400 ج.م');
  });

  testWidgets('a window that never moved draws no sparkline', (tester) async {
    _desktop(tester);

    await tester.pumpWidget(
      _wrap(state: BusinessOverviewLoaded(buildOverview())),
    );
    await tester.pumpAndSettle();

    final bookings = tester.widget<DashboardKpiCard>(
      find.widgetWithText(DashboardKpiCard, 'حجوزات الفترة'),
    );
    expect(
      bookings.sparkline,
      isNull,
      reason: 'a flat line on the floor contradicts a tile reading zero',
    );
  });

  testWidgets('narrow windows stack without overflowing', (tester) async {
    _desktop(tester, size: const Size(600, 2600));

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
    expect(find.byType(PeriodKpiBand), findsOneWidget);
  });

  testWidgets('the console width holds up at 1.6× text scale', (tester) async {
    _desktop(tester, size: const Size(1280, 3200));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: _wrap(
          state: BusinessOverviewLoaded(
            buildOverview(
              trips: [buildTrip(id: 't1', capacity: 10, bookedSeats: 7)],
              bookings: [buildBooking(id: 'b1', amount: 500)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
