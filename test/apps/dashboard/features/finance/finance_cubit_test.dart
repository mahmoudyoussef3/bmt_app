import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_attention.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/repositories/finance_repository.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/export_finance_statement_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_refund_requests_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_wallet_position_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_state.dart';

void main() {
  group('FinanceCubit', () {
    late _MockFinanceRepository repository;
    late FinanceCubit cubit;

    setUp(() {
      repository = _MockFinanceRepository();
      cubit = FinanceCubit(
        getPayments: GetPaymentsUseCase(repository),
        getRefundRequests: GetRefundRequestsUseCase(repository),
        getSubscriptions: GetFinanceSubscriptionsUseCase(repository),
        getWalletPosition: GetWalletPositionUseCase(repository),
        exportStatement: ExportFinanceStatementUseCase(repository),
      );
    });

    tearDown(() => cubit.close());

    test('initial state is FinanceLoading', () {
      expect(cubit.state, isA<FinanceLoading>());
    });

    test('load() builds one ledger from bookings and subscriptions', () async {
      await cubit.load();

      final state = cubit.state as FinanceLoaded;
      expect(state.ledger, hasLength(4));
      expect(
        state.ledger.where((e) => e.type == FinanceEntryType.subscription),
        hasLength(1),
      );
      expect(state.refundRequests, isNotEmpty);
    });

    test('load() surfaces a read failure as FinanceError', () async {
      repository.throwOnRead = true;
      await cubit.load();
      expect(cubit.state, isA<FinanceError>());
    });

    test('load() keeps the selected period when refreshing', () async {
      await cubit.load();
      cubit.setPeriod(FinancePeriod.quarter);
      await cubit.load();

      expect((cubit.state as FinanceLoaded).period, FinancePeriod.quarter);
    });

    test('selectSection() switches the visible report', () async {
      await cubit.load();
      cubit.selectSection(FinanceSection.reports);

      expect((cubit.state as FinanceLoaded).section, FinanceSection.reports);
    });

    test('setPeriod() resets ledger pagination', () async {
      await cubit.load();
      cubit.setLedgerPage(3);
      cubit.setPeriod(FinancePeriod.week);

      expect((cubit.state as FinanceLoaded).ledgerPage, 0);
    });

    test('a ledger filter never changes the period figures', () async {
      await cubit.load();
      cubit.setTypeFilter(FinanceEntryType.subscription);

      final state = cubit.state as FinanceLoaded;
      expect(state.filteredEntries, hasLength(1));
      expect(state.filteredNet, 250);
      expect(state.analytics.netRevenue, 400);
    });

    test('search matches client name and reference', () async {
      await cubit.load();
      cubit.setSearchQuery('القاهرة');

      expect((cubit.state as FinanceLoaded).filteredEntries, hasLength(2));
    });

    test('clearFilters() restores the full ledger', () async {
      await cubit.load();
      cubit.setSearchQuery('لا يوجد');
      cubit.setMethodFilter(FinancePaymentMethod.card);
      expect((cubit.state as FinanceLoaded).filteredEntries, isEmpty);

      cubit.clearFilters();
      final state = cubit.state as FinanceLoaded;
      expect(state.hasAnyFilter, isFalse);
      expect(state.filteredEntries, hasLength(state.analytics.entries.length));
    });

    test('exportStatement() reports the saved file name', () async {
      await cubit.load();
      await cubit.exportStatement('csv');

      final state = cubit.state as FinanceLoaded;
      expect(state.exporting, isFalse);
      expect(state.actionMessage, contains('statement.csv'));
      expect(repository.exportedFormats, ['csv']);
    });

    test('a failed export keeps the loaded screen and its filters', () async {
      await cubit.load();
      cubit.setTypeFilter(FinanceEntryType.booking);
      repository.throwOnExport = true;

      await cubit.exportStatement('pdf');

      final state = cubit.state as FinanceLoaded;
      expect(state.typeFilter, FinanceEntryType.booking);
      expect(state.exporting, isFalse);
      expect(state.actionMessage, contains('تعذر تصدير التقرير'));
    });

    test(
      'pending refund requests are reported as an outstanding amount',
      () async {
        await cubit.load();

        final state = cubit.state as FinanceLoaded;
        expect(state.pendingRefundRequests, hasLength(1));
        expect(state.pendingRefundAmount, 60);
      },
    );

    test('a refund request awaiting a decision reaches the attention list',
        () async {
      await cubit.load();

      final attention = (cubit.state as FinanceLoaded).attention;
      expect(
        attention.items.map((i) => i.kind),
        contains(FinanceAttentionKind.refundRequestsPending),
      );
      expect(attention.totalAtRisk, 60);
    });

    group('derivation is reused when its inputs have not moved', () {
      // The analytics walk the ledger twice and bucket it six ways. Doing that
      // on every keystroke, page turn and tab switch was the module's largest
      // avoidable cost on Flutter Web; these tests are what stops it coming
      // back the next time `copyWith` is extended.

      test('typing in the search box does not re-derive the period', () async {
        await cubit.load();
        final before = cubit.state as FinanceLoaded;

        cubit.setSearchQuery('خالد');
        final after = cubit.state as FinanceLoaded;

        expect(identical(before.analytics, after.analytics), isTrue);
        expect(identical(before.attention, after.attention), isTrue);
        expect(after.searchQuery, 'خالد');
      });

      test('paging and tab switches reuse it too', () async {
        await cubit.load();
        final before = cubit.state as FinanceLoaded;

        cubit.setLedgerPage(2);
        cubit.selectSection(FinanceSection.reports);
        cubit.setLedgerSort(FinanceLedgerSort.amountDesc);
        final after = cubit.state as FinanceLoaded;

        expect(identical(before.analytics, after.analytics), isTrue);
      });

      test('changing the period does re-derive it', () async {
        await cubit.load();
        final before = cubit.state as FinanceLoaded;

        cubit.setPeriod(FinancePeriod.week);
        final after = cubit.state as FinanceLoaded;

        expect(identical(before.analytics, after.analytics), isFalse);
        expect(after.analytics.period, FinancePeriod.week);
      });
    });

    group('the custom range', () {
      test('applying two dates scopes the window to them', () async {
        await cubit.load();
        final now = (cubit.state as FinanceLoaded).loadedAt;

        cubit.setCustomRange(
          now.subtract(const Duration(days: 7)),
          now.subtract(const Duration(days: 3)),
        );

        final state = cubit.state as FinanceLoaded;
        expect(state.period, FinancePeriod.custom);
        expect(state.analytics.window.start!.hour, 0);
        expect(state.analytics.window.end.hour, 23);
      });

      test('dates given backwards are still read as a range', () async {
        await cubit.load();
        final now = (cubit.state as FinanceLoaded).loadedAt;

        cubit.setCustomRange(
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 9)),
        );

        final window = (cubit.state as FinanceLoaded).analytics.window;
        expect(window.start!.isBefore(window.end), isTrue);
      });

      test('selecting the custom preset with no range is refused', () async {
        // Resolving it would silently fall back to the default window while the
        // chip claimed a custom one — two different periods on one screen.
        await cubit.load();

        cubit.setPeriod(FinancePeriod.custom);

        expect((cubit.state as FinanceLoaded).period, FinancePeriod.month);
      });

      test('a chosen range survives a refresh', () async {
        await cubit.load();
        final now = (cubit.state as FinanceLoaded).loadedAt;
        cubit.setCustomRange(
          now.subtract(const Duration(days: 7)),
          now.subtract(const Duration(days: 3)),
        );

        await cubit.load();

        expect((cubit.state as FinanceLoaded).period, FinancePeriod.custom);
        expect((cubit.state as FinanceLoaded).customRange, isNotNull);
      });
    });

    test('the export file name survives a period label with a slash', () {
      // Calendar and custom windows put `/` and `()` into the label, and a
      // slash is a path separator rather than a character — the download either
      // fails or lands somewhere nobody asked for.
      expect(
        FinanceRepositoryImpl.exportFileName(
          '2026/08/01 — 2026/08/10',
          '2026-08-21',
        ),
        'التقرير_المالي_2026_08_01_2026_08_10_2026-08-21',
      );
      expect(
        FinanceRepositoryImpl.exportFileName(
          'هذا الشهر (أغسطس 2026)',
          '2026-08-21',
        ),
        'التقرير_المالي_هذا_الشهر_أغسطس_2026_2026-08-21',
      );
      expect(
        FinanceRepositoryImpl.exportFileName('آخر ٣٠ يوم', '2026-08-21'),
        'التقرير_المالي_آخر_٣٠_يوم_2026-08-21',
      );
    });

    test('the ledger can be re-ordered without touching the figures', () async {
      await cubit.load();
      final net = (cubit.state as FinanceLoaded).analytics.netRevenue;

      cubit.setLedgerSort(FinanceLedgerSort.amountDesc);
      final state = cubit.state as FinanceLoaded;

      expect(state.analytics.netRevenue, net);
      final amounts = state.filteredEntries.map((e) => e.amount).toList();
      expect(amounts, List.of(amounts)..sort((a, b) => b.compareTo(a)));
    });
  });
}

class _MockFinanceRepository implements FinanceRepository {
  /// Fixed "now" so period windows are deterministic. Every record below is
  /// placed relative to it.
  static final _now = DateTime.now();

  bool throwOnRead = false;
  bool throwOnExport = false;
  final List<String> exportedFormats = [];

  /// This office has never issued wallet credit, so the three statements
  /// reduce to the legacy figures — which is exactly the regression this fake
  /// protects: adding the wallet reads must not move any existing number.
  @override
  Future<WalletFinancePosition> getWalletPosition() async {
    if (throwOnRead) throw Exception('فشل تحميل أرصدة المحافظ');
    return const WalletFinancePosition.empty();
  }

  @override
  Future<List<PaymentRecord>> getPayments() async {
    if (throwOnRead) throw Exception('فشل تحميل المدفوعات');
    return [
      PaymentRecord(
        id: 'TXN-1',
        clientName: 'خالد أحمد',
        tripCode: 'القاهرة - الإسكندرية',
        amount: 100,
        paymentMethod: FinancePaymentMethod.instapay,
        status: PaymentStatus.success,
        date: _now,
      ),
      PaymentRecord(
        id: 'TXN-2',
        clientName: 'منى سعيد',
        tripCode: 'القاهرة - طنطا',
        amount: 50,
        paymentMethod: FinancePaymentMethod.cash,
        status: PaymentStatus.success,
        date: _now.subtract(const Duration(days: 5)),
      ),
      // Received then reversed: must land in refunded, never in net revenue.
      PaymentRecord(
        id: 'TXN-3',
        clientName: 'أحمد فؤاد',
        tripCode: 'أسيوط - سوهاج',
        amount: 80,
        paymentMethod: FinancePaymentMethod.card,
        status: PaymentStatus.refunded,
        date: _now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async {
    if (throwOnRead) throw Exception('فشل تحميل الاشتراكات');
    return [
      SubscriptionRecord(
        id: 'SUB-1',
        clientName: 'خالد أحمد',
        packageName: 'الباقة الشهرية',
        amount: 250,
        createdAt: _now.subtract(const Duration(days: 10)),
        startDate: _now.subtract(const Duration(days: 10)),
        endDate: _now.add(const Duration(days: 20)),
        status: SubscriptionStatus.active,
        remainingRides: 10,
      ),
    ];
  }

  @override
  Future<List<RefundRequest>> getRefundRequests() async {
    if (throwOnRead) throw Exception('فشل تحميل طلبات الاسترداد');
    return [
      RefundRequest(
        id: 'REF-1',
        transactionId: 'TXN-9',
        clientName: 'سارة محمود',
        amount: 60,
        date: _now.subtract(const Duration(days: 1)),
        status: RefundStatus.pending,
        reason: 'إلغاء الرحلة',
      ),
    ];
  }

  @override
  Future<RevenueMetrics> getRevenueMetrics() async => const RevenueMetrics(
    todayRevenue: 0,
    weeklyRevenue: 0,
    monthlyRevenue: 0,
    activeSubscriptions: 1,
    totalBookingsRevenue: 0,
  );

  @override
  Future<String> exportStatement(
    FinanceStatement statement,
    String format,
  ) async {
    if (throwOnExport) throw Exception('تعذر حفظ الملف');
    exportedFormats.add(format);
    return 'statement.$format';
  }
}
