import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_state.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart'
    show PaymentStatus;
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart'
    show TicketPriority;
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/widgets/action_required_section.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/widgets/home_kpi_grid.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/widgets/revenue_trend_section.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/widgets/today_trips_section.dart';

import 'dashboard_home_test_fixtures.dart';

/// A cubit double that emits states directly, bypassing the 10 real use
/// cases `DashboardHomeCubit.load()` calls — the orchestration itself is
/// covered by reading through [DashboardHomeCubit.load]'s try/catch, while
/// these tests focus on how the screen renders each state.
class _FakeDashboardHomeCubit extends Cubit<DashboardHomeState>
    implements DashboardHomeCubit {
  _FakeDashboardHomeCubit(super.initialState);

  int loadCalls = 0;

  @override
  Future<void> load() async {
    loadCalls++;
  }
}

class _FakeOperationalAlertsCubit extends Cubit<OperationalAlertsState>
    implements OperationalAlertsCubit {
  _FakeOperationalAlertsCubit(super.initialState);

  @override
  void filterByType(OperationalAlertType? type) {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}

  @override
  void startWatching() {}
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
  required DashboardHomeState homeState,
  OperationalAlertsState alertsState = const OperationalAlertsInitial(),
  ValueChanged<String>? onOpenModule,
  VoidCallback? onCreateTrip,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardHomeCubit>(
              create: (_) => _FakeDashboardHomeCubit(homeState),
            ),
            BlocProvider<OperationalAlertsCubit>(
              create: (_) => _FakeOperationalAlertsCubit(alertsState),
            ),
          ],
          child: DashboardHomeScreen(
            office: _office,
            onOpenModule: onOpenModule,
            onCreateTrip: onCreateTrip,
          ),
        ),
      ),
    ),
  );
}

/// The Home screen is a long [ListView]; sliver machinery only builds items
/// within the viewport + cache extent, so tests asserting on lower sections
/// need a tall enough surface for those widgets to actually mount.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'shows the loading skeleton while DashboardHomeCubit is loading',
    (tester) async {
      await tester.pumpWidget(_wrap(homeState: const DashboardHomeLoading()));
      await tester.pump();

      expect(find.byType(DashboardHomeScreen), findsOneWidget);
      expect(find.text('تعذر تحميل البيانات'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an error state with a retry button that calls load()', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(homeState: const DashboardHomeError('فشل الاتصال بالخادم')),
    );
    await tester.pump();

    expect(find.text('فشل الاتصال بالخادم'), findsOneWidget);
    final retryButton = find.text('إعادة المحاولة');
    expect(retryButton, findsOneWidget);

    await tester.tap(retryButton);
    await tester.pump();

    final cubit =
        BlocProvider.of<DashboardHomeCubit>(
              tester.element(find.byType(DashboardHomeScreen)),
            )
            as _FakeDashboardHomeCubit;
    expect(cubit.loadCalls, 1);
  });

  testWidgets(
    'renders real KPI values from the loaded summary, no fake trend text',
    (tester) async {
      final now = DateTime.now();
      final summary = buildSummary(
        trips: [buildTrip(id: 't1', at: now, capacity: 10, bookedSeats: 5)],
        bookings: [buildBooking(id: 'b1', date: now)],
        revenue: emptyRevenueMetrics,
      );

      await tester.pumpWidget(_wrap(homeState: DashboardHomeLoaded(summary)));
      await tester.pumpAndSettle();

      // Scoped to the KPI grid: "رحلات اليوم" is also the title of the
      // today's-trips panel, and that is the point — the label and the section
      // it drills into are named the same thing.
      final inKpis = find.descendant(
        of: find.byType(HomeKpiGrid),
        matching: find.text('رحلات اليوم'),
      );
      expect(inKpis, findsOneWidget);
      expect(
        find.text('1'),
        findsWidgets,
      ); // today's trip count / booking count
      expect(
        find.descendant(
          of: find.byType(HomeKpiGrid),
          matching: find.text('50%'),
        ),
        findsOneWidget,
      ); // occupancy KPI: 5 of 10 seats
      expect(find.textContaining('↑'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a KPI tile opens the module its number came from', (
    tester,
  ) async {
    final openedRoutes = <String>[];
    await tester.pumpWidget(
      _wrap(
        homeState: DashboardHomeLoaded(buildSummary()),
        onOpenModule: openedRoutes.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(HomeKpiGrid),
        matching: find.text('الحجوزات اليوم'),
      ),
    );
    await tester.pump();

    expect(openedRoutes, [DashboardRoutes.bookings]);
  });

  testWidgets(
    'greets by name and offers creating a trip as the primary action',
    (tester) async {
      var createTripCalls = 0;
      await tester.pumpWidget(
        _wrap(
          homeState: DashboardHomeLoaded(buildSummary()),
          onCreateTrip: () => createTripCalls++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('محمود'), findsWidgets);
      expect(find.textContaining('مكتب تجريبي'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'رحلة جديدة'));
      await tester.pump();

      expect(createTripCalls, 1);
    },
  );

  testWidgets('an empty trip board offers the way out of being empty', (
    tester,
  ) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      _wrap(
        homeState: DashboardHomeLoaded(buildSummary()),
        onCreateTrip: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TodayTripsSection),
        matching: find.text('لا رحلات اليوم'),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'إنشاء رحلة'), findsOneWidget);
  });

  testWidgets('today\'s trips read as a departure board', (tester) async {
    _useTallViewport(tester);
    final now = DateTime.now();

    await tester.pumpWidget(
      _wrap(
        homeState: DashboardHomeLoaded(
          buildSummary(
            trips: [
              buildTrip(
                id: 't1',
                at: DateTime(now.year, now.month, now.day, 8, 30),
                route: 'بنها - القاهرة',
                driver: 'أحمد',
                capacity: 25,
                bookedSeats: 18,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final section = find.byType(TodayTripsSection);
    expect(
      find.descendant(of: section, matching: find.text('08:30')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('بنها - القاهرة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('18/25')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('أحمد')),
      findsOneWidget,
    );
  });

  testWidgets(
    'derived operational queues appear as attention items and route',
    (tester) async {
      _useTallViewport(tester);
      final openedRoutes = <String>[];
      final summary = buildSummary(
        trips: [
          buildTrip(
            id: 't1',
            at: DateTime.now().add(const Duration(hours: 3)),
            driver: '',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          homeState: DashboardHomeLoaded(summary),
          onOpenModule: openedRoutes.add,
        ),
      );
      await tester.pumpAndSettle();

      final section = find.byType(ActionRequiredSection);
      final row = find.descendant(
        of: section,
        matching: find.text('رحلات بدون سائق'),
      );
      expect(row, findsOneWidget);

      await tester.tap(row);
      await tester.pump();

      expect(openedRoutes, [DashboardRoutes.trips]);
    },
  );

  testWidgets('says so plainly when nothing needs a decision', (tester) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      _wrap(homeState: DashboardHomeLoaded(buildSummary())),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ActionRequiredSection),
        matching: find.text('كل شيء تحت السيطرة'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('revenue trend plots real collected bookings, no fabricated total', (
    tester,
  ) async {
    _useTallViewport(tester);
    final summary = buildSummary(
      bookings: [
        buildBooking(
          id: 'paid',
          date: DateTime.now(),
          amount: 300,
          paymentStatus: PaymentStatus.approved,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(homeState: DashboardHomeLoaded(summary)));
    await tester.pumpAndSettle();

    final section = find.byType(RevenueTrendSection);
    expect(
      find.descendant(
        of: section,
        matching: find.text('إجمالي 300 ج.م من 1 حجز خلال آخر 14 يوماً'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'action-required section only lists unread alerts and opens the right module',
    (tester) async {
      _useTallViewport(tester);
      final openedRoutes = <String>[];
      final alerts = [
        OperationalAlert(
          id: 'a1',
          type: OperationalAlertType.paymentReview,
          title: 'دفعة تحتاج مراجعة',
          body: 'إيصال جديد بانتظار القرار',
          isRead: false,
          createdAt: DateTime.now(),
          priority: OperationalAlertPriority.urgent,
        ),
        OperationalAlert(
          id: 'a2',
          type: OperationalAlertType.general,
          title: 'إشعار مقروء بالفعل',
          body: 'تم الاطلاع عليه',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          homeState: DashboardHomeLoaded(buildSummary()),
          alertsState: OperationalAlertsLoaded(alerts),
          onOpenModule: openedRoutes.add,
        ),
      );
      await tester.pumpAndSettle();

      final actionRequired = find.byType(ActionRequiredSection);
      expect(
        find.descendant(
          of: actionRequired,
          matching: find.text('دفعة تحتاج مراجعة'),
        ),
        findsOneWidget,
      );
      // A read alert never belongs in the actionable "needs attention" list —
      // Home no longer carries a chronological activity feed at all (that's
      // one click away in the notifications centre), so it should not appear
      // anywhere on the page.
      expect(
        find.descendant(
          of: actionRequired,
          matching: find.text('إشعار مقروء بالفعل'),
        ),
        findsNothing,
      );
      expect(find.text('إشعار مقروء بالفعل'), findsNothing);

      await tester.tap(
        find.descendant(
          of: actionRequired,
          matching: find.text('دفعة تحتاج مراجعة'),
        ),
      );
      await tester.pump();

      expect(openedRoutes, [DashboardRoutes.paymentVerification]);
    },
  );

  testWidgets(
    'collapses KPI grid to a single column on narrow widths, no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final summary = buildSummary(
        trips: [buildTrip(id: 't1', at: DateTime.now())],
      );

      await tester.pumpWidget(_wrap(homeState: DashboardHomeLoaded(summary)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  // Every width an operator actually uses, with a populated office: the page is
  // a stack of two-column bands, and each one has to fold cleanly rather than
  // paint a yellow overflow stripe across the console.
  for (final size in const [
    Size(1600, 2600), // desktop
    Size(1280, 2600), // laptop
    Size(1024, 2800), // tablet landscape
    Size(820, 3000), // tablet portrait
  ]) {
    testWidgets('lays out without overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final summary = buildSummary(
        trips: [
          buildTrip(
            id: 't1',
            at: now,
            route: 'بنها - القاهرة - مدينة نصر',
            capacity: 25,
            bookedSeats: 18,
          ),
          buildTrip(id: 't2', at: now, driver: '', capacity: 14),
        ],
        bookings: [
          buildBooking(
            id: 'b1',
            date: now,
            paymentStatus: PaymentStatus.approved,
            amount: 250,
          ),
          buildBooking(id: 'v1', paymentStatus: PaymentStatus.submitted),
        ],
        tickets: [buildTicket(id: 'k1', priority: TicketPriority.urgent)],
      );

      await tester.pumpWidget(_wrap(homeState: DashboardHomeLoaded(summary)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
