import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_filters.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_state.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/repositories/customers_repository.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/usecases/customers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/screens/customers_screen.dart';

import 'customers_test_fixtures.dart';

/// Emits states directly, so these tests exercise rendering rather than the
/// orchestration the cubit tests already cover.
class FakeCustomersCubit extends Cubit<CustomersState>
    implements CustomersCubit {
  FakeCustomersCubit(super.initialState);

  final List<String> calls = [];

  @override
  Future<void> load() async => calls.add('load');

  @override
  Future<void> refresh() async => calls.add('refresh');

  @override
  Future<void> search(String term) async => calls.add('search:$term');

  @override
  Future<void> setPage(int page) async => calls.add('page:$page');

  @override
  Future<void> setSort(CustomerSort value) async =>
      calls.add('sort:${value.wire}');

  @override
  Future<void> clearFilters() async => calls.add('clear');

  @override
  Future<void> applyFilters(CustomerFilters filters) async =>
      calls.add('apply:${filters.activity.wire}');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

CustomersLoadedState loaded({
  CustomerDirectoryPage? page,
  CustomerFilters filters = const CustomerFilters(),
  bool overviewFailed = false,
  bool listLoading = false,
}) => CustomersLoadedState(
  overview: overviewFixture(),
  page: page ?? CustomerDirectoryPage(total: 1, rows: [summaryFixture()]),
  filters: filters,
  overviewFailed: overviewFailed,
  listLoading: listLoading,
);

Future<FakeCustomersCubit> pump(
  WidgetTester tester,
  CustomersState state, {
  Size size = const Size(1600, 1400),
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = FakeCustomersCubit(state);
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
            body: BlocProvider<CustomersCubit>.value(
              value: cubit,
              child: const CustomersScreen(),
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
  late FakeCustomersRepository repository;

  setUp(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();

    // Opening a customer builds CustomerProfileCubit from the graph, as the
    // screen does in the app — so the graph has to hold the profile use cases.
    repository = FakeCustomersRepository();
    dashboardDi.registerLazySingleton<CustomersRepository>(() => repository);
    dashboardDi.registerLazySingleton(
      () => GetCustomerProfileUseCase(repository),
    );
    dashboardDi.registerLazySingleton(
      () => GetCustomerTripsUseCase(repository),
    );
    dashboardDi.registerLazySingleton(
      () => GetCustomerSubscriptionsUseCase(repository),
    );
    dashboardDi.registerLazySingleton(
      () => GetCustomerPaymentsUseCase(repository),
    );
    dashboardDi.registerLazySingleton(
      () => GetCustomerActivityUseCase(repository),
    );
  });

  tearDown(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();
    dashboardDi.reset();
  });

  group('states', () {
    testWidgets('loading shows a skeleton, not a bare spinner', (tester) async {
      await pump(tester, const CustomersLoadingState());

      expect(find.byType(DashboardLoading), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that reloads', (tester) async {
      final cubit = await pump(
        tester,
        const CustomersErrorState('تعذر الاتصال'),
      );

      expect(find.byType(DashboardErrorState), findsOneWidget);
      expect(find.text('تعذر الاتصال'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'إعادة المحاولة'));
      await tester.pump();
      expect(cubit.calls, contains('load'));
    });

    testWidgets('the loaded directory shows the module header and a row', (
      tester,
    ) async {
      await pump(tester, loaded());

      expect(find.text('العملاء'), findsWidgets);
      expect(
        find.text(
          'اعرض العملاء وتابع حجوزاتهم واشتراكاتهم ومدفوعاتهم ونشاطهم مع المكتب.',
        ),
        findsOneWidget,
      );
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('+201000000001'), findsOneWidget);
    });

    testWidgets('an empty base says what would put data here', (tester) async {
      await pump(
        tester,
        loaded(page: const CustomerDirectoryPage(total: 0, rows: [])),
      );

      expect(find.text('لا يوجد عملاء حتى الآن'), findsOneWidget);
      expect(find.byType(DashboardEmptyState), findsOneWidget);
    });

    testWidgets('an empty search is a different message, with a way out', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        loaded(
          page: const CustomerDirectoryPage(total: 0, rows: []),
          filters: const CustomerFilters(search: 'لا-يوجد'),
        ),
      );

      expect(find.text('لم نجد عملاء مطابقين للبحث'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'مسح التصفية'));
      await tester.pump();
      expect(cubit.calls, contains('clear'));
    });

    testWidgets('a failed KPI feed is named, and the list survives', (
      tester,
    ) async {
      await pump(tester, loaded(overviewFailed: true));

      expect(find.textContaining('ملخص العملاء'), findsWidgets);
      expect(find.text('أحمد محمود'), findsOneWidget);
    });

    testWidgets('a refetch dims the rows instead of replacing them', (
      tester,
    ) async {
      await pump(tester, loaded(listLoading: true));

      // The operator keeps their place in the list while it reloads.
      expect(find.text('أحمد محمود'), findsOneWidget);
      final fade = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byType(OpsDataTable),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(fade.opacity, lessThan(1));
    });
  });

  group('KPI tiles', () {
    testWidgets('every headline count renders', (tester) async {
      await pump(tester, loaded());

      expect(find.text('إجمالي العملاء'), findsOneWidget);
      expect(find.text('العملاء النشطون'), findsOneWidget);
      expect(find.text('لديهم اشتراك ساري'), findsOneWidget);
      expect(find.text('لديهم رحلة قادمة'), findsOneWidget);
      // "عملاء جدد" is no longer a tile of its own — it had no filter behind
      // it, so it rides on the total's detail line and keeps the strip to the
      // four tiles every المبيعات module shows.
      expect(find.textContaining('أول حجز خلال ٣٠ يوماً'), findsOneWidget);
    });

    testWidgets('a tile applies the filter that produced its number', (
      tester,
    ) async {
      final cubit = await pump(tester, loaded());

      await tester.tap(find.text('العملاء النشطون'));
      await tester.pump();

      expect(cubit.calls, contains('apply:active'));
    });
  });

  group('table', () {
    testWidgets('opening a customer swaps in the profile workspace', (
      tester,
    ) async {
      await pump(tester, loaded());

      await tester.tap(find.widgetWithText(TextButton, 'فتح الملف').first);
      await tester.pump();

      // The directory is replaced, and the way back is on screen.
      expect(find.text('العودة إلى العملاء'), findsOneWidget);
      expect(find.byType(OpsDataTable), findsNothing);
    });

    testWidgets('a header sort asks the server for that key', (tester) async {
      final cubit = await pump(tester, loaded());

      await tester.tap(find.text('الحجوزات'));
      await tester.pump();

      expect(cubit.calls, contains('sort:bookings'));
    });

    testWidgets('a customer with no subscription says so rather than blank', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          page: CustomerDirectoryPage(
            total: 1,
            rows: [summaryFixture(activePackageName: null)],
          ),
        ),
      );

      expect(find.text('بدون اشتراك'), findsOneWidget);
    });

    testWidgets('a package with no ride allowance omits the "x of y" line', (
      tester,
    ) async {
      await pump(
        tester,
        loaded(
          page: CustomerDirectoryPage(
            total: 1,
            rows: [
              summaryFixture(
                activePackageTripsCount: 0,
                activePackageTripsUsed: 0,
              ),
            ],
          ),
        ),
      );

      expect(find.textContaining('من 0 رحلة'), findsNothing);
    });
  });

  group('responsive', () {
    testWidgets('a narrow window swaps the table for cards', (tester) async {
      await pump(tester, loaded(), size: const Size(900, 1400));

      expect(find.byType(OpsDataTable), findsNothing);
      expect(find.text('أحمد محمود'), findsOneWidget);
      // The card layout closes with the same pager bar the table uses, so
      // paging still works and reads identically in both layouts.
      expect(find.byType(DashboardPager), findsOneWidget);
    });

    testWidgets('renders without overflow across widths and text scales', (
      tester,
    ) async {
      for (final size in const [
        Size(1600, 1400),
        Size(1280, 1400),
        Size(1024, 1400),
        Size(820, 1400),
      ]) {
        for (final scale in const [1.0, 1.3, 1.6]) {
          await pump(tester, loaded(), size: size, textScale: scale);
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at $size @ ${scale}x',
          );
        }
      }
    });

    testWidgets('renders in dark mode', (tester) async {
      await pump(tester, loaded(), brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
      expect(find.text('أحمد محمود'), findsOneWidget);
    });
  });

  group('RTL', () {
    testWidgets('the module lays out right-to-left', (tester) async {
      await pump(tester, loaded());

      final direction = Directionality.of(
        tester.element(find.text('أحمد محمود')),
      );
      expect(direction, TextDirection.rtl);
    });

    testWidgets('the name sits to the start (right) of the row', (
      tester,
    ) async {
      await pump(tester, loaded());

      final name = tester.getRect(find.text('أحمد محمود'));
      final paid = tester.getRect(find.text('1,251 ج.م'));
      // Under RTL the first column is the rightmost one.
      expect(
        name.center.dx,
        greaterThan(paid.center.dx),
        reason: 'the identity column must lead in RTL',
      );
    });
  });
}
