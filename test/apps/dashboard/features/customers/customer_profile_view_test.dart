import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_payment.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_trip.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_state.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/widgets/customer_profile_view.dart';

import 'customers_test_fixtures.dart';

class FakeProfileCubit extends Cubit<CustomerProfileState>
    implements CustomerProfileCubit {
  FakeProfileCubit(super.initialState);

  final List<String> calls = [];

  @override
  String get clientId => 'client-1';

  @override
  Future<void> load() async => calls.add('load');

  @override
  Future<void> refresh() async => calls.add('refresh');

  @override
  Future<void> setTab(CustomerProfileTab tab) async {
    calls.add('tab:${tab.name}');
    final current = state;
    if (current is CustomerProfileLoadedState) emit(current.copyWith(tab: tab));
  }

  @override
  Future<void> showPastTrips(bool past) async => calls.add('past:$past');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

CustomerProfileLoadedState loaded({
  CustomerProfileTab tab = CustomerProfileTab.overview,
  CustomerTabStatus tripsStatus = const CustomerTabStatus(loaded: true),
  CustomerTabStatus subscriptionsStatus = const CustomerTabStatus(loaded: true),
  CustomerTabStatus paymentsStatus = const CustomerTabStatus(loaded: true),
  CustomerTabStatus activityStatus = const CustomerTabStatus(loaded: true),
  CustomerTripsPage? pastTrips,
  CustomerPaymentsPage? payments,
  List<dynamic>? subscriptions,
  bool showPastTrips = false,
  Object? profileOverride,
}) => CustomerProfileLoadedState(
  profile:
      (profileOverride as dynamic) ??
      profileFixture(activeSubscription: subscriptionFixture()),
  tab: tab,
  showPastTrips: showPastTrips,
  pastTrips: pastTrips ?? CustomerTripsPage(total: 1, rows: [tripFixture()]),
  upcomingTrips: const CustomerTripsPage.empty(),
  tripsStatus: tripsStatus,
  subscriptions: subscriptions?.cast() ?? [subscriptionFixture()],
  subscriptionsStatus: subscriptionsStatus,
  payments:
      payments ??
      CustomerPaymentsPage(
        total: 1,
        rows: [paymentFixture()],
        totalApproved: 126.75,
      ),
  paymentsStatus: paymentsStatus,
  activity: [activityFixture()],
  activityStatus: activityStatus,
);

Future<FakeProfileCubit> pump(
  WidgetTester tester,
  CustomerProfileState state, {
  Size size = const Size(1600, 1600),
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = FakeProfileCubit(state);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: brightness == Brightness.dark
          ? DashboardAppTheme.dark()
          : DashboardAppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BlocProvider<CustomerProfileCubit>.value(
              value: cubit,
              child: CustomerProfileView(
                fallbackName: 'أحمد محمود',
                onBack: onBack ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  setUp(() => DashboardSectionStateStore.instance.clear());
  tearDown(() => DashboardSectionStateStore.instance.clear());

  group('frame', () {
    testWidgets('loading still offers the way back', (tester) async {
      await pump(tester, const CustomerProfileLoadingState());

      // Without this the operator is stranded on a spinner with only the
      // sidebar to escape it.
      expect(find.text('العودة إلى العملاء'), findsOneWidget);
      expect(find.byType(DashboardLoading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed profile names the customer and retries', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        const CustomerProfileErrorState('هذا العميل لا يتبع مكتبك'),
      );

      expect(find.text('العودة إلى العملاء'), findsOneWidget);
      expect(find.text('هذا العميل لا يتبع مكتبك'), findsOneWidget);
      expect(find.textContaining('أحمد محمود'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'إعادة المحاولة'));
      await tester.pump();
      expect(cubit.calls, contains('load'));
    });

    testWidgets('back invokes the host', (tester) async {
      var backs = 0;
      await pump(tester, loaded(), onBack: () => backs++);

      await tester.tap(find.text('العودة إلى العملاء'));
      await tester.pump();

      expect(backs, 1);
    });
  });

  group('header', () {
    testWidgets('shows identity, contact and the short id', (tester) async {
      await pump(tester, loaded());

      expect(find.text('أحمد محمود'), findsWidgets);
      expect(find.text('+201000000001'), findsOneWidget);
      expect(find.text('ahmed@example.com'), findsOneWidget);
      expect(find.textContaining('رقم العميل: CLIENT-1'), findsOneWidget);
      expect(find.text('نشط'), findsWidgets);
    });

    testWidgets('renders the deterministic insight chips', (tester) async {
      await pump(tester, loaded());

      expect(find.text('عميل نشط'), findsOneWidget);
      expect(find.text('لديه اشتراك ساري'), findsOneWidget);
    });

    testWidgets('quick actions jump to a tab of this same page', (
      tester,
    ) async {
      final cubit = await pump(tester, loaded());

      await tester.tap(find.widgetWithText(OutlinedButton, 'عرض المدفوعات'));
      await tester.pump();

      expect(cubit.calls, contains('tab:payments'));
    });
  });

  group('tabs', () {
    testWidgets('all five are present and switchable', (tester) async {
      final cubit = await pump(tester, loaded());

      for (final tab in CustomerProfileTab.values) {
        expect(find.text(tab.label), findsWidgets, reason: tab.label);
      }

      await tester.tap(find.text('الاشتراكات').first);
      await tester.pump();
      expect(cubit.calls, contains('tab:subscriptions'));
    });

    testWidgets('نظرة عامة shows the summary figures', (tester) async {
      await pump(tester, loaded());

      expect(find.text('إجمالي الحجوزات'), findsOneWidget);
      expect(find.text('الرحلات المكتملة'), findsOneWidget);
      expect(find.text('الحجوزات الملغاة'), findsOneWidget);
      expect(find.text('رصيد المحفظة'), findsOneWidget);
      expect(find.text('سلوك السفر'), findsOneWidget);
    });

    testWidgets('الرحلات shows the trip and its three status axes', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(tab: CustomerProfileTab.trips, showPastTrips: true),
      );

      expect(find.text('القاهرة → الإسكندرية'), findsWidgets);
      // Booking, payment and boarding are three separate marks, never merged.
      expect(find.text('مؤكد'), findsOneWidget);
      expect(find.text('مقبول'), findsOneWidget);
      expect(find.text('صعد'), findsOneWidget);
    });

    testWidgets('الاشتراكات draws a usage bar when it can be computed', (
      tester,
    ) async {
      await pump(tester, loaded(tab: CustomerProfileTab.subscriptions));

      expect(find.text('الاستخدام'), findsOneWidget);
      expect(find.text('40٪'), findsOneWidget);
    });

    testWidgets('a package with no allowance says why there is no percentage', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          tab: CustomerProfileTab.subscriptions,
          subscriptions: [
            subscriptionFixture(tripsCount: 0, usagePercent: null),
          ],
        ),
      );

      expect(find.text('الاستخدام'), findsNothing);
      expect(
        find.text('لا يمكن حساب نسبة الاستخدام: هذه الباقة لا تحدد عدد رحلات.'),
        findsOneWidget,
      );
    });

    testWidgets('المدفوعات shows money but no processor fields', (
      tester,
    ) async {
      await pump(tester, loaded(tab: CustomerProfileTab.payments));

      expect(find.text('إجمالي المدفوع'), findsOneWidget);
      expect(find.text('126.75 ج.م'), findsWidgets);
      expect(find.text('انستا باي'), findsWidgets);
    });

    testWidgets('a customer with no wallet says so rather than showing zero', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          tab: CustomerProfileTab.payments,
          payments: const CustomerPaymentsPage.empty(),
        ),
      );

      expect(find.text('لم تُفتح محفظة لهذا العميل'), findsOneWidget);
      expect(find.text('لا توجد مدفوعات'), findsOneWidget);
    });

    testWidgets('النشاط renders the timeline', (tester) async {
      await pump(tester, loaded(tab: CustomerProfileTab.activity));

      expect(find.text('تم إنشاء حجز'), findsOneWidget);
    });
  });

  group('partial failure', () {
    testWidgets('one broken tab does not take the header with it', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          tab: CustomerProfileTab.payments,
          paymentsStatus: const CustomerTabStatus(error: 'انقطع الاتصال'),
        ),
      );

      // The identity and the summary came from a different request and are
      // still true.
      expect(find.text('أحمد محمود'), findsWidgets);
      expect(find.text('العودة إلى العملاء'), findsOneWidget);
      expect(find.text('تعذر تحميل هذا القسم'), findsOneWidget);
      // And the failure is named up top as well.
      expect(find.textContaining('المدفوعات'), findsWidgets);
    });

    testWidgets('a stale tab keeps its rows and warns above them', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          tab: CustomerProfileTab.subscriptions,
          subscriptionsStatus: const CustomerTabStatus(
            loaded: true,
            error: 'انقطع الاتصال',
          ),
        ),
      );

      expect(find.textContaining('قد تكون قديمة'), findsOneWidget);
      expect(find.text('أسبوع عمل (٥ أيام)'), findsWidgets);
    });
  });

  group('layout', () {
    testWidgets('renders without overflow across widths and text scales', (
      tester,
    ) async {
      for (final tab in CustomerProfileTab.values) {
        for (final size in const [
          Size(1600, 1800),
          Size(1200, 1800),
          Size(900, 1800),
        ]) {
          for (final scale in const [1.0, 1.6]) {
            await pump(
              tester,
              loaded(tab: tab, showPastTrips: true),
              size: size,
              textScale: scale,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${tab.label} at $size @ ${scale}x',
            );
          }
        }
      }
    });

    testWidgets('renders in dark mode', (tester) async {
      await pump(tester, loaded(), brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
      expect(find.text('عميل نشط'), findsOneWidget);
    });

    testWidgets('lays out right-to-left', (tester) async {
      await pump(tester, loaded());

      expect(
        Directionality.of(tester.element(find.text('+201000000001'))),
        TextDirection.rtl,
      );
    });
  });
}
