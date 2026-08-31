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
  void setLedgerSort(FinanceLedgerSort sort) {}
  @override
  void setCustomRange(DateTime start, DateTime end) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      current.copyWith(
        period: FinancePeriod.custom,
        customRange: FinanceDateRange(start: start, end: end),
      ),
    );
  }

  @override
  void clearActionMessage() {}
}

final _now = DateTime(2026, 7, 31, 14, 30);

FinanceLoaded _loadedState({
  FinancePeriod period = FinancePeriod.month,
  FinanceSection section = FinanceSection.overview,
  bool capReached = false,
  bool withAttention = false,

  /// Drops the outstanding fare, leaving a book with nothing waiting on a
  /// decision — the state the attention panel has to say something about.
  bool nothingPending = false,
  List<RefundRequest> refundRequests = const [],
}) {
  return FinanceLoaded(
    ledger: FinanceLedger.build(
      payments: [
        if (withAttention)
          PaymentRecord(
            id: 'TXN-9',
            clientName: 'سارة محمود',
            tripCode: 'Obour, QH, Egypt → New Cairo, QH, Egypt',
            amount: 210,
            paymentMethod: FinancePaymentMethod.instapay,
            status: PaymentStatus.pending,
            date: _now.subtract(const Duration(days: 1)),
            awaitingReview: true,
            context: const FinanceEntryContext(
              reference: 'BK-000999',
              phone: '01000000000',
              origin: 'Obour, QH, Egypt',
              destination: 'New Cairo, QH, Egypt',
              hasReceipt: true,
            ),
          ),
        PaymentRecord(
          id: 'TXN-1',
          clientName: 'خالد أحمد',
          tripCode: 'القاهرة - الإسكندرية',
          amount: 300,
          paymentMethod: FinancePaymentMethod.instapay,
          status: PaymentStatus.success,
          date: _now.subtract(const Duration(days: 1)),
        ),
        if (!nothingPending)
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
    refundRequests: refundRequests,
    subscriptions: const [],
    loadedAt: _now,
    period: period,
    section: section,
    ledgerCapReached: capReached,
  );
}

/// A ledger whose every string is longer than anything a fixture would
/// otherwise carry: a full Arabic quadruple name, a geocoder-length route, and
/// a seven-figure fare.
FinanceLoaded _longNameState({
  FinanceSection section = FinanceSection.overview,
}) {
  return FinanceLoaded(
    ledger: FinanceLedger.build(
      payments: [
        PaymentRecord(
          id: 'TXN-LONG-0000-0000-0000-0000-0000-0000',
          clientName: 'عبد الرحمن محمد عبد الفتاح الشناوي المصري',
          tripCode:
              'Obour City, Qalyubia Governorate, Egypt → American University '
              'in Cairo (AUC) - New Cairo, Qalyubia Governorate, Egypt',
          amount: 1234567.89,
          paymentMethod: FinancePaymentMethod.instapay,
          status: PaymentStatus.success,
          date: _now.subtract(const Duration(days: 1)),
          context: const FinanceEntryContext(
            reference: 'BK-0000000000123456',
            phone: '01000000000',
            origin: 'Obour City, Qalyubia Governorate, Egypt',
            destination:
                'American University in Cairo (AUC) - New Cairo, '
                'Qalyubia Governorate, Egypt',
          ),
        ),
        PaymentRecord(
          id: 'TXN-LONG-2',
          clientName: 'فاطمة الزهراء عبد المنعم أبو العلا',
          tripCode: 'المنصورة، محافظة الدقهلية → القاهرة الجديدة، محافظة القاهرة',
          amount: 987654.32,
          paymentMethod: FinancePaymentMethod.vodafoneCash,
          status: PaymentStatus.pending,
          date: _now.subtract(const Duration(days: 2)),
          awaitingReview: true,
        ),
      ],
      subscriptions: [
        SubscriptionRecord(
          id: 'SUB-LONG',
          clientName: 'محمود إبراهيم عبد العزيز السيد',
          packageName: 'الباقة الشهرية الممتدة — عشرون رحلة ذهاب وعودة',
          amount: 500000,
          createdAt: _now.subtract(const Duration(days: 3)),
          startDate: _now.subtract(const Duration(days: 3)),
          endDate: _now.add(const Duration(days: 27)),
          status: SubscriptionStatus.active,
          remainingRides: 8,
          paidAmount: 300000,
          remainingAmount: 200000,
        ),
      ],
    ),
    refundRequests: const [],
    subscriptions: const [],
    loadedAt: _now,
    section: section,
  );
}

Widget _wrap(
  FinanceState state, {
  _FakeFinanceCubit? cubit,
  ValueChanged<String>? onOpenModule,
  double textScale = 1,
}) {
  final screen = Directionality(
    textDirection: TextDirection.rtl,
    child: BlocProvider<FinanceCubit>(
      create: (_) => cubit ?? _FakeFinanceCubit(state),
      child: FinanceScreen(onOpenModule: onOpenModule),
    ),
  );

  return MaterialApp(
    home: Scaffold(
      body: textScale == 1
          ? screen
          : Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: screen,
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

  testWidgets('the period bar states the window it resolved to', (
    tester,
  ) async {
    // A chip that says "هذا الشهر" is a name, not a boundary. The dates have to
    // be on screen or the reader cannot tell which window produced a figure.
    _useTallViewport(tester);
    await tester.pumpWidget(_wrap(_loadedState(period: FinancePeriod.week)));
    await tester.pump();

    expect(find.textContaining('من 2026/07/25 إلى 2026/07/31'), findsOneWidget);
    expect(find.textContaining('المقارنة مع'), findsOneWidget);
  });

  testWidgets('a calendar month is named and bounded to the month', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(
      _wrap(_loadedState(period: FinancePeriod.lastMonth)),
    );
    await tester.pump();

    expect(find.textContaining('يونيو 2026'), findsWidgets);
    expect(find.textContaining('من 2026/06/01 إلى 2026/06/30'), findsOneWidget);
  });

  group('يحتاج المتابعة', () {
    testWidgets('a clear board says so rather than rendering nothing', (
      tester,
    ) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap(_loadedState(nothingPending: true)));
      await tester.pumpAndSettle();

      expect(find.text('يحتاج المتابعة'), findsOneWidget);
      expect(
        find.textContaining('لا شيء معلق'),
        findsWidgets,
        reason: 'an empty panel is indistinguishable from a failed one',
      );
    });

    testWidgets('an uncollected fare on a live seat is a queue of its own', (
      tester,
    ) async {
      // The category an earlier query dropped entirely. If this stops
      // appearing, the module has gone back to under-reporting what it is owed.
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap(_loadedState()));
      await tester.pumpAndSettle();

      expect(find.text('حجوزات قائمة لم تُحصّل'), findsOneWidget);
      expect(find.text('120 ج.م'), findsWidgets);
    });

    testWidgets('an undecided receipt is listed with its count and money', (
      tester,
    ) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap(_loadedState(withAttention: true)));
      await tester.pumpAndSettle();

      expect(find.text('إيصالات بانتظار المراجعة'), findsOneWidget);
      expect(find.text('1 إيصال'), findsOneWidget);
      expect(find.text('راجع الإيصال واقبله أو ارفضه'), findsOneWidget);
    });

    testWidgets('a queue hands the operator off to the module that owns it', (
      tester,
    ) async {
      _useTallViewport(tester);
      final opened = <String>[];
      await tester.pumpWidget(
        _wrap(
          _loadedState(withAttention: true),
          onOpenModule: opened.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إيصالات بانتظار المراجعة'));
      await tester.pumpAndSettle();

      expect(opened, ['/payment-verification']);
    });

    testWidgets('pending refunds are counted from the requests, not the ledger',
        (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          _loadedState(
            refundRequests: [
              RefundRequest(
                id: 'REF-1',
                transactionId: 'TXN-1',
                clientName: 'سارة محمود',
                amount: 68,
                date: _now.subtract(const Duration(days: 1)),
                status: RefundStatus.pending,
                reason: 'إلغاء الرحلة',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('طلبات استرداد بلا قرار'), findsOneWidget);
      expect(find.text('1 طلب'), findsOneWidget);
    });

    testWidgets('the overview tab carries the count as a badge', (
      tester,
    ) async {
      _useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(_loadedState(withAttention: true, section: FinanceSection.reports)),
      );
      await tester.pumpAndSettle();

      // Working in التقارير must not mean being the last to know.
      expect(find.text('1'), findsWidgets);
    });
  });

  group('nothing overflows', () {
    // The console is used at 1366×768 as often as at 1920, and Arabic office
    // and passenger names are long. An overflow here is a red-striped box in
    // production, which is why these run at the narrow end and with names
    // longer than any real fixture.
    for (final width in const [1100.0, 1366.0, 1440.0, 1920.0]) {
      testWidgets('at ${width.toInt()}px wide', (tester) async {
        tester.view.physicalSize = Size(width, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_longNameState()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    // The console declares a 1.6× accessibility scale, and every block on this
    // screen is Arabic text in a fixed-height tile or a side-by-side pair. The
    // cheapest way to find a P0 here is to pump one.
    for (final width in const [1180.0, 1440.0]) {
      testWidgets('at ${width.toInt()}px wide and 1.6× text', (tester) async {
        tester.view.physicalSize = Size(width, 5000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final section in FinanceSection.values) {
          await tester.pumpWidget(
            _wrap(_longNameState(section: section), textScale: 1.6),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow in ${section.label} at ${width.toInt()}px / 1.6×',
          );
        }
      });
    }

    testWidgets('with a large amount and a long route on the ledger', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(_longNameState(section: FinanceSection.ledger)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('transaction detail', () {
    testWidgets('a ledger row opens into its full context', (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          _loadedState(
            withAttention: true,
            section: FinanceSection.ledger,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('سارة محمود'));
      await tester.pumpAndSettle();

      expect(find.text('حركة حجز رحلة'), findsOneWidget);
      expect(find.text('BK-000999'), findsOneWidget);
      expect(find.text('01000000000'), findsOneWidget);
      expect(find.textContaining('210'), findsWidgets);
      expect(
        find.textContaining('خارج صافي الإيراد'),
        findsOneWidget,
        reason: 'a row has to explain what it did to the headline figure',
      );
    });

    testWidgets('the detail sheet decides nothing', (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          _loadedState(withAttention: true, section: FinanceSection.ledger),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('سارة محمود'));
      await tester.pumpAndSettle();

      for (final forbidden in const ['قبول', 'رفض', 'استرداد', 'إلغاء الحجز']) {
        expect(find.widgetWithText(FilledButton, forbidden), findsNothing);
        expect(find.widgetWithText(TextButton, forbidden), findsNothing);
      }
      expect(find.text('إغلاق'), findsOneWidget);
    });
  });
}
