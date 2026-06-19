import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/finance_entities.dart';
import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/get_receipt_reviews_usecase.dart';
import '../../domain/usecases/get_refund_requests_usecase.dart';
import '../../domain/usecases/get_revenue_metrics_usecase.dart';
import '../../domain/usecases/get_revenue_trend_usecase.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';
import '../../domain/usecases/process_refund_usecase.dart';
import '../../domain/usecases/review_receipt_usecase.dart';
import 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  final GetPaymentsUseCase _getPayments;
  final GetReceiptReviewsUseCase _getReceiptReviews;
  final GetRefundRequestsUseCase _getRefundRequests;
  final GetFinanceSubscriptionsUseCase _getSubscriptions;
  final GetRevenueMetricsUseCase _getRevenueMetrics;
  final GetRevenueTrendUseCase _getRevenueTrend;
  final ReviewReceiptUseCase _reviewReceipt;
  final ProcessRefundUseCase _processRefund;
  final CancelFinanceSubscriptionUseCase _cancelSubscription;

  FinanceCubit({
    required GetPaymentsUseCase getPayments,
    required GetReceiptReviewsUseCase getReceiptReviews,
    required GetRefundRequestsUseCase getRefundRequests,
    required GetFinanceSubscriptionsUseCase getSubscriptions,
    required GetRevenueMetricsUseCase getRevenueMetrics,
    required GetRevenueTrendUseCase getRevenueTrend,
    required ReviewReceiptUseCase reviewReceipt,
    required ProcessRefundUseCase processRefund,
    required CancelFinanceSubscriptionUseCase cancelSubscription,
  }) : _getPayments = getPayments,
       _getReceiptReviews = getReceiptReviews,
       _getRefundRequests = getRefundRequests,
       _getSubscriptions = getSubscriptions,
       _getRevenueMetrics = getRevenueMetrics,
       _getRevenueTrend = getRevenueTrend,
       _reviewReceipt = reviewReceipt,
       _processRefund = processRefund,
       _cancelSubscription = cancelSubscription,
       super(const FinanceLoading());

  Future<void> load() async {
    emit(const FinanceLoading());
    try {
      final payments = await _getPayments();
      final receipts = await _getReceiptReviews();
      final refunds = await _getRefundRequests();
      final subscriptions = await _getSubscriptions();
      final metrics = await _getRevenueMetrics();
      final revenueTrend = await _getRevenueTrend();

      // Find first pending receipt review to pre-select it
      final firstPendingReceipt = receipts.cast<ReceiptReview?>().firstWhere(
        (r) => r?.status == ReceiptReviewStatus.pending,
        orElse: () => receipts.isNotEmpty ? receipts.first : null,
      );

      // Find first pending refund to pre-select it
      final firstPendingRefund = refunds.cast<RefundRequest?>().firstWhere(
        (r) => r?.status == RefundStatus.pending,
        orElse: () => refunds.isNotEmpty ? refunds.first : null,
      );

      emit(
        FinanceLoaded(
          payments: payments,
          receiptReviews: receipts,
          refundRequests: refunds,
          subscriptions: subscriptions,
          metrics: metrics,
          revenueTrend: revenueTrend,
          selectedPaymentId: payments.isNotEmpty ? payments.first.id : null,
          selectedReceiptId: firstPendingReceipt?.id,
          selectedRefundId: firstPendingRefund?.id,
          selectedSubscriptionId: subscriptions.isNotEmpty
              ? subscriptions.first.id
              : null,
        ),
      );
    } catch (error) {
      emit(FinanceError(error.toString()));
    }
  }

  void selectSection(int index) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      current.copyWith(selectedSectionIndex: index, clearActionMessage: true),
    );
  }

  void selectPayment(String? id) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (id == null) {
      emit(current.copyWith(clearPaymentSelection: true));
    } else {
      emit(current.copyWith(selectedPaymentId: id));
    }
  }

  void selectReceipt(String? id) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (id == null) {
      emit(current.copyWith(clearReceiptSelection: true));
    } else {
      emit(
        current.copyWith(
          selectedReceiptId: id,
          receiptZoom: 1.0,
          receiptRotation: 0.0,
        ),
      );
    }
  }

  void selectRefund(String? id) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (id == null) {
      emit(current.copyWith(clearRefundSelection: true));
    } else {
      emit(current.copyWith(selectedRefundId: id));
    }
  }

  void selectSubscription(String? id) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (id == null) {
      emit(current.copyWith(clearSubscriptionSelection: true));
    } else {
      emit(current.copyWith(selectedSubscriptionId: id));
    }
  }

  void setPaymentMethodFilter(FinancePaymentMethod? method) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (method == null) {
      emit(current.copyWith(clearPaymentMethodFilter: true));
    } else {
      emit(current.copyWith(paymentMethodFilter: method));
    }
  }

  void setPaymentStatusFilter(PaymentStatus? status) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (status == null) {
      emit(current.copyWith(clearPaymentStatusFilter: true));
    } else {
      emit(current.copyWith(paymentStatusFilter: status));
    }
  }

  void setReceiptStatusFilter(ReceiptReviewStatus? status) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (status == null) {
      emit(current.copyWith(clearReceiptStatusFilter: true));
    } else {
      emit(current.copyWith(receiptStatusFilter: status));
    }
  }

  void setRefundStatusFilter(RefundStatus? status) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (status == null) {
      emit(current.copyWith(clearRefundStatusFilter: true));
    } else {
      emit(current.copyWith(refundStatusFilter: status));
    }
  }

  void setSubscriptionStatusFilter(SubscriptionStatus? status) {
    final current = state;
    if (current is! FinanceLoaded) return;
    if (status == null) {
      emit(current.copyWith(clearSubscriptionStatusFilter: true));
    } else {
      emit(current.copyWith(subscriptionStatusFilter: status));
    }
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  void setReceiptZoom(double zoom) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(receiptZoom: zoom.clamp(0.5, 3.0)));
  }

  void setReceiptRotation(double rotation) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(receiptRotation: rotation));
  }

  void clearActionMessage() {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(clearActionMessage: true));
  }

  Future<void> reviewReceipt(
    String id,
    ReceiptReviewStatus action, {
    String? notes,
  }) async {
    final current = state;
    if (current is! FinanceLoaded) return;

    emit(current.copyWith(actionLoading: true, clearActionMessage: true));
    try {
      await _reviewReceipt(id, action, notes: notes);

      final payments = await _getPayments();
      final receipts = await _getReceiptReviews();
      final metrics = await _getRevenueMetrics();

      // Find next pending receipt review to pre-select
      ReceiptReview? nextPending;
      for (final r in receipts) {
        if (r.status == ReceiptReviewStatus.pending && r.id != id) {
          nextPending = r;
          break;
        }
      }
      if (nextPending == null) {
        for (final r in receipts) {
          if (r.id != id) {
            nextPending = r;
            break;
          }
        }
      }

      emit(
        current.copyWith(
          payments: payments,
          receiptReviews: receipts,
          metrics: metrics,
          selectedReceiptId: nextPending?.id,
          clearReceiptSelection: nextPending == null,
          actionLoading: false,
          actionMessage: 'تم تحديث حالة الإيصال بنجاح إلى: ${action.label}',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionLoading: false,
          actionMessage: 'خطأ: ${error.toString()}',
        ),
      );
    }
  }

  Future<void> processRefund(String id, RefundStatus action) async {
    final current = state;
    if (current is! FinanceLoaded) return;

    emit(current.copyWith(actionLoading: true, clearActionMessage: true));
    try {
      await _processRefund(id, action);

      final payments = await _getPayments();
      final refunds = await _getRefundRequests();
      final metrics = await _getRevenueMetrics();

      emit(
        current.copyWith(
          payments: payments,
          refundRequests: refunds,
          metrics: metrics,
          actionLoading: false,
          actionMessage: 'تم تحديث طلب المرتجع بنجاح إلى: ${action.label}',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionLoading: false,
          actionMessage: 'خطأ: ${error.toString()}',
        ),
      );
    }
  }

  Future<void> cancelSubscription(String id) async {
    final current = state;
    if (current is! FinanceLoaded) return;

    emit(current.copyWith(actionLoading: true, clearActionMessage: true));
    try {
      await _cancelSubscription(id);

      final subscriptions = await _getSubscriptions();
      final metrics = await _getRevenueMetrics();

      emit(
        current.copyWith(
          subscriptions: subscriptions,
          metrics: metrics,
          actionLoading: false,
          actionMessage: 'تم إلغاء الاشتراك بنجاح.',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionLoading: false,
          actionMessage: 'خطأ: ${error.toString()}',
        ),
      );
    }
  }
}
