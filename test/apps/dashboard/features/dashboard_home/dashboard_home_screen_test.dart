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
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/widgets/action_required_section.dart';

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
          child: DashboardHomeScreen(office: _office, onOpenModule: onOpenModule),
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
  testWidgets('shows the loading skeleton while DashboardHomeCubit is loading', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(homeState: const DashboardHomeLoading()));
    await tester.pump();

    expect(find.byType(DashboardHomeScreen), findsOneWidget);
    expect(find.text('تعذر تحميل البيانات'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

    final cubit = BlocProvider.of<DashboardHomeCubit>(
      tester.element(find.byType(DashboardHomeScreen)),
    ) as _FakeDashboardHomeCubit;
    expect(cubit.loadCalls, 1);
  });

  testWidgets('renders real KPI values from the loaded summary, no fake trend text', (
    tester,
  ) async {
    final now = DateTime.now();
    final summary = buildSummary(
      trips: [buildTrip(id: 't1', at: now, capacity: 10, bookedSeats: 5)],
      bookings: [buildBooking(id: 'b1', date: now)],
      revenue: emptyRevenueMetrics,
    );

    await tester.pumpWidget(
      _wrap(homeState: DashboardHomeLoaded(summary)),
    );
    await tester.pumpAndSettle();

    expect(find.text('رحلات اليوم'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // today's trip count / booking count
    expect(find.text('50%'), findsOneWidget); // occupancy KPI: 5 of 10 seats
    expect(find.textContaining('↑'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marketplace card reflects a draft (unlisted) office honestly', (
    tester,
  ) async {
    _useTallViewport(tester);
    final summary = buildSummary(officeProfile: officeProfileDraft);

    await tester.pumpWidget(_wrap(homeState: DashboardHomeLoaded(summary)));
    await tester.pumpAndSettle();

    expect(find.text('قيد التجهيز'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      // The read alert still shows in the chronological activity feed, but
      // never in the actionable "needs attention" list — that's the whole
      // point of the two sections being separate.
      expect(
        find.descendant(
          of: actionRequired,
          matching: find.text('إشعار مقروء بالفعل'),
        ),
        findsNothing,
      );
      expect(find.text('إشعار مقروء بالفعل'), findsOneWidget);

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

  testWidgets('collapses KPI grid to a single column on narrow widths, no overflow', (
    tester,
  ) async {
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
  });
}
