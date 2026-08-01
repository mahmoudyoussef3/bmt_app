import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_state.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/screens/finance_screen.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/widgets/finance_analytics_tab.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/widgets/finance_ledger_tab.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/widgets/finance_overview_tab.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/widgets/finance_reports_tab.dart';

/// Emits states directly so the screen tests exercise rendering, not the
/// use-case orchestration already covered by the cubit tests.
class _FakeFinanceCubit extends Cubit<FinanceState> implements FinanceCubit {
  _FakeFinanceCubit(super.initialState);

  int loadCalls = 0;
  final List<String> exportedFormats = [];

  @override
  Future<void> load() async => loadCalls++;

  @override
  Future<void> exportStatement(String format) async =>
      exportedFormats.add(format);

  @override
  void selectSection(FinanceSection section) {
    final current = state;
    if (current is FinanceLoaded) emit(current.copyWith(section: section));
  }

  @override
  void setPeriod(FinancePeriod period) {
    final current = state;
    if (current is FinanceLoaded) emit(current.copyWith(period: period));
  }

  @override
  void setSearchQuery(String query) {}
  @override
  void setTypeFilter(FinanceEntryType? type) {}
  @override
  void setMethodFilter(FinancePaymentMethod? method) {}
  @override
  void setStatusFilter(PaymentStatus? status) {}
  @override
  void clearFilters() {}
  @override
  void setLedgerPage(int page) {}
  @override
  void clearActionMessage() {}
}

final _now = DateTime(2026, 7, 31, 14, 30);

FinanceLoaded _loadedState({
  FinancePeriod period = FinancePeriod.month,
  FinanceSection section = FinanceSection.overview,
  bool capReached = false,
}) {
  return FinanceLoaded(
    ledger: FinanceLedger.build(
      payments: [
        PaymentRecord(
          id: 'TXN-1',
          clientName: 'خالد أحمد',
          tripCode: 'القاهرة - الإسكندرية',
          amount: 300,
          paymentMethod: FinancePaymentMethod.instapay,
          status: PaymentStatus.success,
          date: _now.subtract(const Duration(days: 1)),
        ),
        PaymentRecord(
          id: 'TXN-2',
          clientName: 'منى سعيد',
          tripCode: 'القاهرة - طنطا',
          amount: 120,
          paymentMethod: FinancePaymentMethod.cash,
          status: PaymentStatus.pending,
          date: _now.subtract(const Duration(days: 2)),
        ),
      ],
      subscriptions: [
        SubscriptionRecord(
          id: 'SUB-1',
          clientName: 'خالد أحمد',
          packageName: 'الباقة الشهرية',
          amount: 500,
          createdAt: _now.subtract(const Duration(days: 3)),
          startDate: _now.subtract(const Duration(days: 3)),
          endDate: _now.add(const Duration(days: 27)),
          status: SubscriptionStatus.active,
          remainingRides: 8,
        ),
      ],
    ),
    refundRequests: const [],
    subscriptions: const [],
    loadedAt: _now,
    period: period,
    section: section,
    ledgerCapReached: capReached,
  );
}

Widget _wrap(FinanceState state, {_FakeFinanceCubit? cubit}) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<FinanceCubit>(
          create: (_) => cubit ?? _FakeFinanceCubit(state),
          child: const FinanceScreen(),
        ),
      ),
    ),
  );
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders the loading skeleton without error', (tester) async {
    await tester.pumpWidget(_wrap(const FinanceLoading()));
    await tester.pump();

    expect(find.byType(FinanceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an error state offers a retry that reloads', (tester) async {
    final cubit = _FakeFinanceCubit(const FinanceError('فشل الاتصال بالخادم'));
    await tester.pumpWidget(_wrap(const FinanceError(''), cubit: cubit));
    await tester.pump();

    expect(find.text('فشل الاتصال بالخادم'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();

    expect(cubit.loadCalls, 1);
  });

  testWidgets('the loaded screen leads with net revenue for the period', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_wrap(_loadedState()));
    await tester.pumpAndSettle();

    expect(find.text('المركز المالي'), findsOneWidget);
    // 300 booking + 500 subscription collected; the 120 pending stays out.
    expect(find.text('800 ج.م'), findsWidgets);
    expect(find.byType(FinanceOverviewTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('states plainly that verification happens in Bookings', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_wrap(_loadedState()));
    await tester.pump();

    expect(
      find.text('التحقق من إثباتات الدفع يتم في قسم الحجوزات'),
      findsOneWidget,
    );
  });

  testWidgets('offers no approve / reject / verify control anywhere', (
    tester,
  ) async {
    _useTallViewport(tester);

    for (final section in FinanceSection.values) {
      await tester.pumpWidget(_wrap(_loadedState(section: section)));
      await tester.pumpAndSettle();

      for (final forbidden in const [
        'قبول',
        'رفض',
        'مراجعة الإيصال',
        'إلغاء الاشتراك',
        'الموافقة',
        'طلب إعادة رفع',
      ]) {
        expect(
          find.text(forbidden),
          findsNothing,
          reason:
              '"$forbidden" is a Bookings action and must not appear in '
              'Finance (section: ${section.label})',
        );
      }
    }
  });

  testWidgets('switching tabs swaps the report shown', (tester) async {
    _useTallViewport(tester);
    final cubit = _FakeFinanceCubit(_loadedState());
    await tester.pumpWidget(_wrap(_loadedState(), cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text(FinanceSection.ledger.label));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceLedgerTab), findsOneWidget);

    await tester.tap(find.text(FinanceSection.analytics.label));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceAnalyticsTab), findsOneWidget);

    await tester.tap(find.text(FinanceSection.reports.label));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceReportsTab), findsOneWidget);
  });

  testWidgets('choosing a period re-scopes the figures', (tester) async {
    _useTallViewport(tester);
    final cubit = _FakeFinanceCubit(_loadedState());
    await tester.pumpWidget(_wrap(_loadedState(), cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text(FinancePeriod.today.label));
    await tester.pumpAndSettle();

    expect((cubit.state as FinanceLoaded).period, FinancePeriod.today);
    // Nothing was collected today in the fixture, so the headline must say so
    // rather than keep showing the month's number.
    expect(find.text('0 ج.م'), findsWidgets);
  });

  testWidgets('the reports tab exports the period statement', (tester) async {
    _useTallViewport(tester);
    final cubit = _FakeFinanceCubit(
      _loadedState(section: FinanceSection.reports),
    );
    await tester.pumpWidget(
      _wrap(_loadedState(section: FinanceSection.reports), cubit: cubit),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CSV'));
    await tester.pump();

    expect(cubit.exportedFormats, ['csv']);
  });

  testWidgets('a capped ledger says so instead of under-reporting silently', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_wrap(_loadedState(capReached: true)));
    await tester.pump();

    expect(find.textContaining('يعرض أحدث'), findsOneWidget);
  });
}
