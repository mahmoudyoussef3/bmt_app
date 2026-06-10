import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/repositories/finance_repository.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/cancel_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_receipt_reviews_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_refund_requests_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_revenue_metrics_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/process_refund_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/review_receipt_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_state.dart';

void main() {
  group('FinanceCubit Tests', () {
    late _MockFinanceRepository repository;
    late FinanceCubit cubit;

    setUp(() {
      repository = _MockFinanceRepository();
      cubit = FinanceCubit(
        getPayments: GetPaymentsUseCase(repository),
        getReceiptReviews: GetReceiptReviewsUseCase(repository),
        getRefundRequests: GetRefundRequestsUseCase(repository),
        getSubscriptions: GetFinanceSubscriptionsUseCase(repository),
        getRevenueMetrics: GetRevenueMetricsUseCase(repository),
        reviewReceipt: ReviewReceiptUseCase(repository),
        processRefund: ProcessRefundUseCase(repository),
        cancelSubscription: CancelFinanceSubscriptionUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is FinanceLoading', () {
      expect(cubit.state, isA<FinanceLoading>());
    });

    test('load() success emits FinanceLoaded with records', () async {
      await cubit.load();
      expect(cubit.state, isA<FinanceLoaded>());
      final state = cubit.state as FinanceLoaded;
      expect(state.payments, isNotEmpty);
      expect(state.receiptReviews, isNotEmpty);
      expect(state.refundRequests, isNotEmpty);
      expect(state.subscriptions, isNotEmpty);
    });

    test('selectSection() changes section index', () async {
      await cubit.load();
      cubit.selectSection(1);
      final state = cubit.state as FinanceLoaded;
      expect(state.selectedSectionIndex, 1);
    });

    test('reviewReceipt() accepts receipt and updates payment status', () async {
      await cubit.load();
      await cubit.reviewReceipt('REC-1', ReceiptReviewStatus.accepted, notes: 'مقبول');
      final state = cubit.state as FinanceLoaded;
      expect(state.receiptReviews.firstWhere((r) => r.id == 'REC-1').status, ReceiptReviewStatus.accepted);
      expect(state.payments.firstWhere((p) => p.id == 'TXN-1').status, PaymentStatus.success);
    });

    test('processRefund() approves refund request', () async {
      await cubit.load();
      await cubit.processRefund('REF-1', RefundStatus.approved);
      final state = cubit.state as FinanceLoaded;
      expect(state.refundRequests.firstWhere((r) => r.id == 'REF-1').status, RefundStatus.approved);
    });

    test('cancelSubscription() cancels active subscription', () async {
      await cubit.load();
      await cubit.cancelSubscription('SUB-1');
      final state = cubit.state as FinanceLoaded;
      expect(state.subscriptions.firstWhere((s) => s.id == 'SUB-1').status, SubscriptionStatus.cancelled);
    });
  });
}

class _MockFinanceRepository implements FinanceRepository {
  List<PaymentRecord> payments = [
    PaymentRecord(
      id: 'TXN-1',
      clientName: 'خالد أحمد',
      tripCode: 'TRIP-101',
      amount: 150.0,
      paymentMethod: FinancePaymentMethod.instapay,
      status: PaymentStatus.pending,
      date: DateTime.now(),
    ),
  ];

  List<ReceiptReview> receipts = [
    ReceiptReview(
      id: 'REC-1',
      transactionId: 'TXN-1',
      clientName: 'خالد أحمد',
      tripCode: 'TRIP-101',
      amount: 150.0,
      date: DateTime.now(),
      receiptUrl: 'assets/receipt.png',
      status: ReceiptReviewStatus.pending,
      history: const ['تم الرفع'],
    ),
  ];

  List<RefundRequest> refunds = [
    RefundRequest(
      id: 'REF-1',
      transactionId: 'TXN-1',
      clientName: 'خالد أحمد',
      amount: 150.0,
      date: DateTime.now(),
      status: RefundStatus.pending,
      reason: 'إلغاء الرحلة',
      history: const ['تقديم الطلب'],
    ),
  ];

  List<SubscriptionRecord> subscriptions = [
    SubscriptionRecord(
      id: 'SUB-1',
      clientName: 'خالد أحمد',
      packageName: 'الباقة الشهرية',
      amount: 500.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      status: SubscriptionStatus.active,
      remainingRides: 10,
    ),
  ];

  RevenueMetrics metrics = const RevenueMetrics(
    todayRevenue: 0,
    weeklyRevenue: 0,
    monthlyRevenue: 0,
    activeSubscriptions: 1,
    totalBookingsRevenue: 0,
  );

  @override
  Future<List<PaymentRecord>> getPayments() async => payments;

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async => receipts;

  @override
  Future<List<RefundRequest>> getRefundRequests() async => refunds;

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async => subscriptions;

  @override
  Future<RevenueMetrics> getRevenueMetrics() async => metrics;

  @override
  Future<void> reviewReceipt(String id, ReceiptReviewStatus action, {String? notes}) async {
    final idx = receipts.indexWhere((r) => r.id == id);
    if (idx != -1) {
      receipts[idx] = receipts[idx].copyWith(status: action, notes: notes);
      if (action == ReceiptReviewStatus.accepted) {
        final pIdx = payments.indexWhere((p) => p.id == receipts[idx].transactionId);
        if (pIdx != -1) {
          payments[pIdx] = payments[pIdx].copyWith(status: PaymentStatus.success);
        }
      }
    }
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    final idx = refunds.indexWhere((r) => r.id == id);
    if (idx != -1) {
      refunds[idx] = refunds[idx].copyWith(status: action);
    }
  }

  @override
  Future<void> cancelSubscription(String id) async {
    final idx = subscriptions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      subscriptions[idx] = subscriptions[idx].copyWith(status: SubscriptionStatus.cancelled);
    }
  }
}
