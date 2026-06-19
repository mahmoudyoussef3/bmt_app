import '../../domain/entities/finance_entities.dart';

sealed class FinanceState {
  const FinanceState();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceError extends FinanceState {
  final String message;
  const FinanceError(this.message);
}

class FinanceLoaded extends FinanceState {
  final List<PaymentRecord> payments;
  final List<ReceiptReview> receiptReviews;
  final List<RefundRequest> refundRequests;
  final List<SubscriptionRecord> subscriptions;
  final RevenueMetrics metrics;
  final List<RevenueTrendPoint> revenueTrend;

  final int selectedSectionIndex; // 0: المدفوعات, 1: طلبات المراجعة, 2: المرتجعات, 3: الاشتراكات, 4: الإيرادات
  final String? selectedPaymentId;
  final String? selectedReceiptId;
  final String? selectedRefundId;
  final String? selectedSubscriptionId;

  final FinancePaymentMethod? paymentMethodFilter;
  final PaymentStatus? paymentStatusFilter;
  final ReceiptReviewStatus? receiptStatusFilter;
  final RefundStatus? refundStatusFilter;
  final SubscriptionStatus? subscriptionStatusFilter;
  final String searchQuery;

  final bool actionLoading;
  final String? actionMessage;
  final double receiptZoom;
  final double receiptRotation;

  const FinanceLoaded({
    required this.payments,
    required this.receiptReviews,
    required this.refundRequests,
    required this.subscriptions,
    required this.metrics,
    this.revenueTrend = const [],
    this.selectedSectionIndex = 0,
    this.selectedPaymentId,
    this.selectedReceiptId,
    this.selectedRefundId,
    this.selectedSubscriptionId,
    this.paymentMethodFilter,
    this.paymentStatusFilter,
    this.receiptStatusFilter,
    this.refundStatusFilter,
    this.subscriptionStatusFilter,
    this.searchQuery = '',
    this.actionLoading = false,
    this.actionMessage,
    this.receiptZoom = 1.0,
    this.receiptRotation = 0.0,
  });

  PaymentRecord? get selectedPayment {
    if (selectedPaymentId == null) return null;
    return payments.cast<PaymentRecord?>().firstWhere(
      (p) => p?.id == selectedPaymentId,
      orElse: () => null,
    );
  }

  ReceiptReview? get selectedReceipt {
    if (selectedReceiptId == null) return null;
    return receiptReviews.cast<ReceiptReview?>().firstWhere(
      (r) => r?.id == selectedReceiptId,
      orElse: () => null,
    );
  }

  RefundRequest? get selectedRefund {
    if (selectedRefundId == null) return null;
    return refundRequests.cast<RefundRequest?>().firstWhere(
      (r) => r?.id == selectedRefundId,
      orElse: () => null,
    );
  }

  SubscriptionRecord? get selectedSubscription {
    if (selectedSubscriptionId == null) return null;
    return subscriptions.cast<SubscriptionRecord?>().firstWhere(
      (s) => s?.id == selectedSubscriptionId,
      orElse: () => null,
    );
  }

  /// Realised revenue (everything except cancelled) grouped by payment method.
  Map<FinancePaymentMethod, double> get revenueByMethod {
    final map = <FinancePaymentMethod, double>{};
    for (final p in payments) {
      if (p.status == PaymentStatus.cancelled) continue;
      map[p.paymentMethod] = (map[p.paymentMethod] ?? 0) + p.amount;
    }
    return map;
  }

  /// Amount grouped by payment status (paid / pending / refunded / cancelled).
  Map<PaymentStatus, double> get amountByStatus {
    final map = <PaymentStatus, double>{};
    for (final p in payments) {
      map[p.status] = (map[p.status] ?? 0) + p.amount;
    }
    return map;
  }

  /// Top routes by realised revenue (descending), capped to [limit].
  List<MapEntry<String, double>> revenueByRoute([int limit = 6]) {
    final map = <String, double>{};
    for (final p in payments) {
      if (p.status == PaymentStatus.cancelled) continue;
      final route = p.tripCode.isEmpty ? 'غير محدد' : p.tripCode;
      map[route] = (map[route] ?? 0) + p.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  FinanceLoaded copyWith({
    List<PaymentRecord>? payments,
    List<ReceiptReview>? receiptReviews,
    List<RefundRequest>? refundRequests,
    List<SubscriptionRecord>? subscriptions,
    RevenueMetrics? metrics,
    List<RevenueTrendPoint>? revenueTrend,
    int? selectedSectionIndex,
    String? selectedPaymentId,
    String? selectedReceiptId,
    String? selectedRefundId,
    String? selectedSubscriptionId,
    bool clearPaymentSelection = false,
    bool clearReceiptSelection = false,
    bool clearRefundSelection = false,
    bool clearSubscriptionSelection = false,
    FinancePaymentMethod? paymentMethodFilter,
    bool clearPaymentMethodFilter = false,
    PaymentStatus? paymentStatusFilter,
    bool clearPaymentStatusFilter = false,
    ReceiptReviewStatus? receiptStatusFilter,
    bool clearReceiptStatusFilter = false,
    RefundStatus? refundStatusFilter,
    bool clearRefundStatusFilter = false,
    SubscriptionStatus? subscriptionStatusFilter,
    bool clearSubscriptionStatusFilter = false,
    String? searchQuery,
    bool? actionLoading,
    String? actionMessage,
    bool clearActionMessage = false,
    double? receiptZoom,
    double? receiptRotation,
  }) {
    return FinanceLoaded(
      payments: payments ?? this.payments,
      receiptReviews: receiptReviews ?? this.receiptReviews,
      refundRequests: refundRequests ?? this.refundRequests,
      subscriptions: subscriptions ?? this.subscriptions,
      metrics: metrics ?? this.metrics,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      selectedSectionIndex: selectedSectionIndex ?? this.selectedSectionIndex,
      selectedPaymentId: clearPaymentSelection ? null : (selectedPaymentId ?? this.selectedPaymentId),
      selectedReceiptId: clearReceiptSelection ? null : (selectedReceiptId ?? this.selectedReceiptId),
      selectedRefundId: clearRefundSelection ? null : (selectedRefundId ?? this.selectedRefundId),
      selectedSubscriptionId: clearSubscriptionSelection ? null : (selectedSubscriptionId ?? this.selectedSubscriptionId),
      paymentMethodFilter: clearPaymentMethodFilter ? null : (paymentMethodFilter ?? this.paymentMethodFilter),
      paymentStatusFilter: clearPaymentStatusFilter ? null : (paymentStatusFilter ?? this.paymentStatusFilter),
      receiptStatusFilter: clearReceiptStatusFilter ? null : (receiptStatusFilter ?? this.receiptStatusFilter),
      refundStatusFilter: clearRefundStatusFilter ? null : (refundStatusFilter ?? this.refundStatusFilter),
      subscriptionStatusFilter: clearSubscriptionStatusFilter ? null : (subscriptionStatusFilter ?? this.subscriptionStatusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      receiptZoom: receiptZoom ?? this.receiptZoom,
      receiptRotation: receiptRotation ?? this.receiptRotation,
    );
  }
}
