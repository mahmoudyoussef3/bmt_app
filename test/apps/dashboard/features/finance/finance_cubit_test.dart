import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/repositories/finance_repository.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/export_finance_statement_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_refund_requests_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_subscriptions_usecase.dart';
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
  });
}

class _MockFinanceRepository implements FinanceRepository {
  /// Fixed "now" so period windows are deterministic. Every record below is
  /// placed relative to it.
  static final _now = DateTime.now();

  bool throwOnRead = false;
  bool throwOnExport = false;
  final List<String> exportedFormats = [];

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
