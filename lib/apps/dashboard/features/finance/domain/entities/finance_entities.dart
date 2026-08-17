/// Finance is the money-intelligence module: it *reads* every pound that moved
/// and explains it. Verification of payment receipts (approve / reject / ask for
/// a re-upload) deliberately lives in the Bookings module only — an operator
/// must decide on a receipt where the booking context is, and a number here must
/// never be a button.
library;

import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

enum FinancePaymentMethod {
  instapay('انستا باي'),
  vodafoneCash('فودافون كاش'),
  cash('نقدي'),
  card('بطاقة');

  final String label;
  const FinancePaymentMethod(this.label);
}

/// Money vocabulary, not workflow vocabulary: a finance reader cares whether an
/// amount was *collected*, is still *outstanding*, fell through, or went back.
enum PaymentStatus {
  success('محصّلة'),
  pending('قيد التحصيل'),
  cancelled('ملغاة'),
  refunded('مستردة');

  final String label;
  const PaymentStatus(this.label);
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

/// The reporting window every figure on the screen is measured over. One
/// selection drives the KPIs, the charts, the ledger and the exported
/// statement, so two numbers on the same screen can never mean two periods.
enum FinancePeriod {
  today('اليوم', 1),
  week('آخر ٧ أيام', 7),
  month('آخر ٣٠ يوم', 30),
  quarter('آخر ٩٠ يوم', 90),
  all('كل الفترات', null);

  final String label;

  /// Window length in days, counting today. `null` means "no lower bound".
  final int? days;

  const FinancePeriod(this.label, this.days);

  /// First instant included in the window, or `null` for [FinancePeriod.all].
  DateTime? startFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final length = days;
    if (length == null) return null;
    return today.subtract(Duration(days: length - 1));
  }

  /// Start of the equally long window immediately before this one — the basis
  /// for every "مقارنة بالفترة السابقة" figure. `null` when there is nothing
  /// meaningful to compare against.
  DateTime? previousStartFrom(DateTime now) {
    final length = days;
    if (length == null) return null;
    return startFrom(now)!.subtract(Duration(days: length));
  }
}

/// Which side of the business a money movement came from.
enum FinanceEntryType {
  booking('حجز رحلة', 'الحجوزات'),
  subscription('اشتراك باقة', 'الاشتراكات');

  final String label;
  final String pluralLabel;
  const FinanceEntryType(this.label, this.pluralLabel);
}

/// Half-open reporting window `[start, end]` used by the analytics layer.
/// Hand-rolled instead of `DateTimeRange` so the domain stays pure Dart.
class FinanceDateRange {
  final DateTime? start;
  final DateTime end;

  const FinanceDateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    if (date.isAfter(end)) return false;
    final from = start;
    return from == null || !date.isBefore(from);
  }
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

class RefundRequest {
  final String id;
  final String transactionId;
  final String clientName;
  final double amount;
  final DateTime date;
  final RefundStatus status;
  final String reason;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.status,
    required this.reason,
  });

  RefundRequest copyWith({
    String? id,
    String? transactionId,
    String? clientName,
    double? amount,
    DateTime? date,
    RefundStatus? status,
    String? reason,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }
}

class SubscriptionRecord {
  final String id;
  final String clientName;
  final String packageName;
  final double amount;

  /// Purchase date — the date the money moved, and therefore the date the
  /// ledger files it under. [startDate] is when the *rides* begin, which can be
  /// a different day entirely.
  final DateTime createdAt;
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
    required this.createdAt,
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      remainingRides: remainingRides ?? this.remainingRides,
      tripsCount: tripsCount ?? this.tripsCount,
      tripsUsed: tripsUsed ?? this.tripsUsed,
    );
  }
}

/// One money movement, whatever produced it. Trip bookings and package
/// purchases are two different tables but one ledger — reading them together is
/// the only way a revenue figure here can mean "all the money", and netting the
/// refunded rows out of it is the only way "صافي الإيراد" is real.
class FinanceLedgerEntry {
  final String id;
  final FinanceEntryType type;

  /// Who the money came from.
  final String party;

  /// What it was for — a route code for bookings, a package name for
  /// subscriptions.
  final String reference;

  /// Always positive; [PaymentStatus.refunded] is what marks money that came in
  /// and then went back out.
  final double amount;
  final FinancePaymentMethod? method;
  final PaymentStatus status;
  final DateTime date;

  const FinanceLedgerEntry({
    required this.id,
    required this.type,
    required this.party,
    required this.reference,
    required this.amount,
    required this.status,
    required this.date,
    this.method,
  });

  /// Money the office received *and kept* — the only figure that may be added
  /// into net revenue. Everything else is a promise, a dead row, or a reversal.
  bool get isRealised => status == PaymentStatus.success;
}

/// Flattens the money-in sources into one chronological ledger.
///
/// Refunds are **not** appended as separate rows: an approved refund is already
/// mirrored on its booking as [PaymentStatus.refunded], and adding the
/// `refund_requests` row on top of it would subtract the same pound twice.
/// Those requests are read separately, as an outstanding-liability signal.
class FinanceLedger {
  const FinanceLedger._();

  /// How many booking transactions the ledger pulls. Everything on the finance
  /// screen is derived from this list, so the cap is the module's real horizon:
  /// when a load comes back full, the screen says so instead of quietly
  /// under-reporting the older end of the window.
  ///
  /// The number itself lives with the console's other row ceilings so they can
  /// be read against each other; this alias is what the module's own code and
  /// its tests have always called it.
  static const rowCap = DashboardQueryCaps.financeLedger;

  static List<FinanceLedgerEntry> build({
    required List<PaymentRecord> payments,
    required List<SubscriptionRecord> subscriptions,
  }) {
    final entries = <FinanceLedgerEntry>[
      for (final payment in payments)
        FinanceLedgerEntry(
          id: payment.id,
          type: FinanceEntryType.booking,
          party: payment.clientName,
          reference: payment.tripCode.isEmpty ? 'غير محدد' : payment.tripCode,
          amount: payment.amount,
          method: payment.paymentMethod,
          status: payment.status,
          date: payment.date,
        ),
      for (final subscription in subscriptions)
        FinanceLedgerEntry(
          id: subscription.id,
          type: FinanceEntryType.subscription,
          party: subscription.clientName,
          reference: subscription.packageName,
          amount: subscription.amount,
          status: subscriptionMoneyStatus(subscription.status),
          date: subscription.createdAt,
        ),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// A cancelled package was never collected; one still awaiting payment is
  /// outstanding. Everything else (active or expired) was paid for.
  static PaymentStatus subscriptionMoneyStatus(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.active ||
      SubscriptionStatus.expired => PaymentStatus.success,
      SubscriptionStatus.pendingPayment => PaymentStatus.pending,
      SubscriptionStatus.cancelled => PaymentStatus.cancelled,
    };
  }
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

  double get grandTotalRevenue =>
      totalBookingsRevenue + totalSubscriptionsRevenue;

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
