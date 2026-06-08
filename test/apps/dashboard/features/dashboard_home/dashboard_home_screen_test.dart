import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_data.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/repositories/dashboard_home_repository.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/screens/dashboard_home_screen.dart';

void main() {
  testWidgets('DashboardHomeScreen renders empty payment reviews safely', (
    tester,
  ) async {
    final cubit = DashboardHomeCubit(
      GetDashboardHomeUseCase(
        _DashboardHomeRepository(
          const DashboardHomeData(
            actionItems: [],
            todayTrips: [],
            paymentReviews: [],
            openComplaints: [],
            subscriptions: [],
            alerts: [],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..load(),
              child: const DashboardHomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مدفوعات قيد المراجعة'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });

  testWidgets('DashboardHomeScreen opens payment and live-trip action cards', (
    tester,
  ) async {
    final openedRoutes = <String>[];
    final cubit = DashboardHomeCubit(
      GetDashboardHomeUseCase(_DashboardHomeRepository(_interactiveHomeData)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..load(),
              child: DashboardHomeScreen(onOpenModule: openedRoutes.add),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('حجز بانتظار مراجعة الدفع'));
    await tester.pump();
    await tester.tap(find.text('رحلة متأخرة'));
    await tester.pump();

    expect(openedRoutes, [
      DashboardRoutes.paymentVerification,
      DashboardRoutes.liveTrips,
    ]);

    await cubit.close();
  });

  testWidgets('DashboardHomeScreen opens delayed trips in live monitoring', (
    tester,
  ) async {
    final openedRoutes = <String>[];
    final cubit = DashboardHomeCubit(
      GetDashboardHomeUseCase(_DashboardHomeRepository(_interactiveHomeData)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..load(),
              child: DashboardHomeScreen(onOpenModule: openedRoutes.add),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('رحلة عودة ٤٠٧'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('رحلة عودة ٤٠٧'));
    await tester.pump();

    expect(openedRoutes.single, DashboardRoutes.liveTrips);

    await cubit.close();
  });
}

const _interactiveHomeData = DashboardHomeData(
  actionItems: [
    OperationsActionItem(
      title: 'حجز بانتظار مراجعة الدفع',
      count: '١٢',
      description: 'إيصالات تحتاج قرار خدمة العملاء',
      targetModule: DashboardRoutes.paymentVerification,
      priority: OperationsPriority.urgent,
    ),
    OperationsActionItem(
      title: 'رحلة متأخرة',
      count: '٢',
      description: 'تأخير فعلي يحتاج متابعة مباشرة',
      targetModule: DashboardRoutes.liveTrips,
      priority: OperationsPriority.urgent,
    ),
  ],
  todayTrips: [
    TodayTripSummary(
      name: 'رحلة عودة ٤٠٧',
      route: 'القرية الذكية - رمسيس',
      driver: 'محمد سامي',
      vehicle: 'تويوتا هايس',
      departureTime: '٥:٤٥ م',
      capacity: 14,
      bookedSeats: 11,
      status: 'متأخرة',
    ),
  ],
  paymentReviews: [],
  openComplaints: [],
  subscriptions: [],
  alerts: [],
);

class _DashboardHomeRepository implements DashboardHomeRepository {
  final DashboardHomeData data;

  const _DashboardHomeRepository(this.data);

  @override
  Future<DashboardHomeData> getHomeData() async {
    return data;
  }
}
