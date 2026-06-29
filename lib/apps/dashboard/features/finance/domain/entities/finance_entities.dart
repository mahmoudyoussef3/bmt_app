enum FinancePaymentMethod {
  instapay('انستا باي'),
  vodafoneCash('فودافون كاش'),
  cash('نقدي'),
  card('بطاقة');

  final String label;
  const FinancePaymentMethod(this.label);
}

enum PaymentStatus {
  success('ناجحة'),
  pending('معلقة'),
  cancelled('ملغاة'),
  refunded('مستردة');

  final String label;
  const PaymentStatus(this.label);
}

enum ReceiptReviewStatus {
  pending('بانتظار المراجعة'),
  accepted('مقبول'),
  rejected('مرفوض'),
  reuploadRequested('طلب إعادة رفع');

  final String label;
  const ReceiptReviewStatus(this.label);
}

enum RefundStatus {
  pending('بانتظار الموافقة'),
  approved('تمت الموافقة'),
  rejected('مرفوض');

  final String label;
  const RefundStatus(this.label);
}

enum SubscriptionStatus {
  active('نشط'),
  expired('منتهي'),
  cancelled('ملغي'),
  pendingPayment('بانتظار الدفع');

  final String label;
  const SubscriptionStatus(this.label);
}

class PaymentRecord {
  final String id;
  final String clientName;
  final String tripCode;
  final double amount;
  final FinancePaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime date;

  const PaymentRecord({
    required this.id,
    required this.clientName,
    required this.tripCode,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.date,
  });

  PaymentRecord copyWith({
    String? id,
    String? clientName,
    String? tripCode,
    double? amount,
    FinancePaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? date,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      tripCode: tripCode ?? this.tripCode,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }
}

class ReceiptReview {
  final String id;
  final String transactionId;
  final String clientName;
  final String tripCode;
  final double amount;
  final DateTime date;
  final String receiptUrl;
  final ReceiptReviewStatus status;
  final String? notes;
  final List<String> history;

  const ReceiptReview({
    required this.id,
    required this.transactionId,
    required this.clientName,
    required this.tripCode,
    required this.amount,
    required this.date,
    required this.receiptUrl,
    required this.status,
    this.notes,
    required this.history,
  });

  ReceiptReview copyWith({
    String? id,
    String? transactionId,
    String? clientName,
    String? tripCode,
    double? amount,
    DateTime? date,
    String? receiptUrl,
    ReceiptReviewStatus? status,
    String? notes,
    List<String>? history,
  }) {
    return ReceiptReview(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      clientName: clientName ?? this.clientName,
      tripCode: tripCode ?? this.tripCode,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      history: history ?? this.history,
    );
  }
}

class RefundRequest {
  final String id;
  final String transactionId;
  final String clientName;
  final double amount;
  final DateTime date;
  final RefundStatus status;
  final String reason;
  final List<String> history;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.status,
    required this.reason,
    required this.history,
  });

  RefundRequest copyWith({
    String? id,
    String? transactionId,
    String? clientName,
    double? amount,
    DateTime? date,
    RefundStatus? status,
    String? reason,
    List<String>? history,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      history: history ?? this.history,
    );
  }
}

class SubscriptionRecord {
  final String id;
  final String clientName;
  final String packageName;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final int remainingRides;
  final int tripsCount;
  final int tripsUsed;

  const SubscriptionRecord({
    required this.id,
    required this.clientName,
    required this.packageName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.remainingRides,
    this.tripsCount = 0,
    this.tripsUsed = 0,
  });

  SubscriptionRecord copyWith({
    String? id,
    String? clientName,
    String? packageName,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    int? remainingRides,
    int? tripsCount,
    int? tripsUsed,
  }) {
    return SubscriptionRecord(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      packageName: packageName ?? this.packageName,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      remainingRides: remainingRides ?? this.remainingRides,
      tripsCount: tripsCount ?? this.tripsCount,
      tripsUsed: tripsUsed ?? this.tripsUsed,
    );
  }
}

/// A single day on the revenue trend line, sourced from `revenue_daily_view`.
class RevenueTrendPoint {
  final DateTime date;
  final double amount;
  final int bookings;

  const RevenueTrendPoint({
    required this.date,
    required this.amount,
    required this.bookings,
  });
}

class RevenueMetrics {
  final double todayRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int activeSubscriptions;
  final double totalBookingsRevenue;
  final double totalSubscriptionsRevenue;

  const RevenueMetrics({
    required this.todayRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.activeSubscriptions,
    required this.totalBookingsRevenue,
    this.totalSubscriptionsRevenue = 0,
  });

  double get grandTotalRevenue => totalBookingsRevenue + totalSubscriptionsRevenue;

  RevenueMetrics copyWith({
    double? todayRevenue,
    double? weeklyRevenue,
    double? monthlyRevenue,
    int? activeSubscriptions,
    double? totalBookingsRevenue,
    double? totalSubscriptionsRevenue,
  }) {
    return RevenueMetrics(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      totalBookingsRevenue: totalBookingsRevenue ?? this.totalBookingsRevenue,
      totalSubscriptionsRevenue:
          totalSubscriptionsRevenue ?? this.totalSubscriptionsRevenue,
    );
  }
}
