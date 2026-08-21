/// Row → entity translation for the finance module, as pure functions.
///
/// Lifted out of the datasource so the rules that decide *what a number means*
/// can be tested against real database shapes without a Supabase client. Every
/// correctness bug this module has had lived in exactly these five functions —
/// a status the query dropped, a spelling the switch missed, a price counted
/// before it arrived — and none of them was reachable by a test while they sat
/// as private methods behind a network call.
library;

import '../../domain/entities/finance_entities.dart';

abstract final class FinanceRowMapper {
  const FinanceRowMapper._();

  /// A receipt is uploaded and the desk has not decided.
  ///
  /// `payment_status` moves to `submitted` then `underReview`;
  /// `payment_review_status` runs its own `pending / under_review / reviewed`
  /// axis. The payment axis is the one that carries the money, so it is the one
  /// read here.
  static const awaitingReviewStatuses = {'submitted', 'underReview'};

  /// The subscription review states that mean "nobody has accepted this money
  /// yet". Note the underscore — the subscriptions table spells it differently
  /// from the bookings table.
  static const subscriptionReviewPending = {'pending', 'under_review'};

  static PaymentRecord payment(Map<String, dynamic> row) {
    final rawPaymentStatus = row['payment_status']?.toString() ?? '';
    final bookingState = FinanceBookingState.fromDb(row['status']?.toString());
    final route = row['route']?.toString() ?? '';
    final (origin, destination) = splitRoute(
      route,
      pickup: row['pickup_point_name']?.toString(),
      dropoff: row['dropoff_point_name']?.toString(),
    );

    return PaymentRecord(
      id: row['id'].toString(),
      clientName: row['passenger_name']?.toString() ?? 'غير معروف',
      tripCode: route,
      amount: toDouble(row['payment_amount']),
      paymentMethod: method(row['payment_method']?.toString() ?? ''),
      status: paymentStatus(rawPaymentStatus, bookingState),
      date:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      bookingState: bookingState,

      // A receipt on a released seat is not a queue anyone should work: the
      // booking module refuses to approve it, so offering it as a decision
      // would be offering a guaranteed refusal.
      awaitingReview:
          awaitingReviewStatuses.contains(rawPaymentStatus) &&
          bookingState != FinanceBookingState.cancelled,
      context: FinanceEntryContext(
        reference: _nonEmpty(row['booking_number']),
        phone: _nonEmpty(row['phone']),
        origin: origin,
        destination: destination,
        serviceDate: DateTime.tryParse(row['trip_date']?.toString() ?? ''),
        hasReceipt: _nonEmpty(row['payment_receipt_url']) != null,
        rejectionReason: _nonEmpty(row['payment_rejection_reason']),
      ),
    );
  }

  static SubscriptionRecord subscription(
    Map<String, dynamic> row, {
    required DateTime now,
  }) {
    final client = row['client'] as Map<String, dynamic>? ?? const {};
    final startDate =
        DateTime.tryParse(row['start_date']?.toString() ?? '') ?? now;
    final endDate =
        DateTime.tryParse(row['end_date']?.toString() ?? '') ??
        now.add(const Duration(days: 30));

    final tripsCount = toInt(row['trips_count']);
    final tripsUsed = toInt(row['trips_used']);
    final remainingRides = tripsCount > 0
        ? (tripsCount - tripsUsed).clamp(0, tripsCount)
        : endDate.difference(now).inDays.clamp(0, 9999);

    final price = toDouble(row['total_price']);
    final paid = collectedSubscriptionAmount(row);
    final review = row['payment_review_status']?.toString();

    return SubscriptionRecord(
      id: row['id'].toString(),
      clientName:
          _nonEmpty(row['customer_name']) ??
          _nonEmpty(client['full_name']) ??
          'غير معروف',
      packageName: _nonEmpty(row['package_name']) ?? 'باقة',
      amount: price,
      paidAmount: paid,

      // The column is authoritative when present; older rows predate it, and
      // the difference is the same figure by definition.
      remainingAmount: row['remaining_amount'] != null
          ? toDouble(row['remaining_amount'])
          : (price - paid).clamp(0, price).toDouble(),
      awaitingReview: subscriptionReviewPending.contains(review),
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ?? startDate,
      startDate: startDate,
      endDate: endDate,
      status: subscriptionStatus(row['status']?.toString()),
      remainingRides: remainingRides,
      tripsCount: tripsCount,
      tripsUsed: tripsUsed,
    );
  }

  static RefundRequest refund(Map<String, dynamic> row, {DateTime? fallback}) {
    final client = row['client'] as Map<String, dynamic>? ?? const {};
    return RefundRequest(
      id: row['id'].toString(),
      transactionId: row['booking_id']?.toString() ?? '',
      clientName: _nonEmpty(client['full_name']) ?? 'عميل غير معروف',
      amount: toDouble(row['amount']),
      date:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          fallback ??
          DateTime.now(),
      status: refundStatus(row['status']?.toString()),
      reason: row['reason']?.toString() ?? '',
    );
  }

  /// The two ends of a journey.
  ///
  /// `pickup_point_name` / `dropoff_point_name` are authoritative but only
  /// populated on newer rows; `route` is `NOT NULL` and stores the pair already
  /// joined with an arrow. Splitting it back apart is what lets the UI compose
  /// the label with `routeDirectionLabel` — a stored `'A → B'` printed as-is
  /// announces the journey backwards whenever bidi resolves the line the other
  /// way, which for the Latin place names the geocoder returns for most
  /// Egyptian stops is most of the time.
  ///
  /// Returns `(null, null)` when the string carries no separator, and the
  /// caller falls back to printing it whole.
  static (String?, String?) splitRoute(
    String route, {
    String? pickup,
    String? dropoff,
  }) {
    final from = pickup?.trim();
    final to = dropoff?.trim();
    if ((from?.isNotEmpty ?? false) && (to?.isNotEmpty ?? false)) {
      return (from, to);
    }

    for (final separator in const ['→', '←', '->', '<-']) {
      final index = route.indexOf(separator);
      if (index <= 0) continue;
      final head = route.substring(0, index).trim();
      final tail = route.substring(index + separator.length).trim();
      if (head.isEmpty || tail.isEmpty) continue;
      return separator == '←' || separator == '<-'
          ? (tail, head)
          : (head, tail);
    }
    return (null, null);
  }

  /// Money actually received against a package.
  ///
  /// `paid_amount` is the column that means it. It is defaulted rather than
  /// nullable, so the fallback to `total_price` fires only when the key is
  /// absent or null — never when it is present and legitimately zero.
  static double collectedSubscriptionAmount(Map<String, dynamic> row) {
    if (row['paid_amount'] == null) return toDouble(row['total_price']);
    return toDouble(row['paid_amount']);
  }

  /// Normalises the free-text method column.
  ///
  /// The same rail is written several ways across the three apps —
  /// `credit_card` from the client wizard, `Credit Card` from an operator
  /// typing it, `InstaPay` from an older build. Comparing the raw string put
  /// every unrecognised spelling into "نقدي", which is how card payments came
  /// to be reported as cash. Separators and case collapse before matching.
  static FinancePaymentMethod method(String raw) {
    final key = raw.toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');
    return switch (key) {
      'card' || 'credit_card' || 'debit_card' || 'visa' || 'mastercard' =>
        FinancePaymentMethod.card,
      'instapay' || 'insta_pay' => FinancePaymentMethod.instapay,
      'wallet' ||
      'e_wallet' ||
      'ewallet' ||
      'vodafone' ||
      'vodafone_cash' ||
      'etisalat_cash' ||
      'orange_cash' => FinancePaymentMethod.vodafoneCash,
      _ => FinancePaymentMethod.cash,
    };
  }

  /// Maps the database's eight payment states onto the four a money reader
  /// needs, using the seat's own state to settle the ambiguous ones.
  ///
  /// The subtlety is `pending` / `submitted` / `underReview` on a **cancelled**
  /// booking. Those are not "قيد التحصيل": the seat is gone, `approve_payment`
  /// refuses them, and nobody is waiting for the money. Filing them as
  /// outstanding inflates the receivable an owner is chasing with fares that
  /// can never arrive.
  static PaymentStatus paymentStatus(String raw, FinanceBookingState booking) {
    final settled = switch (raw) {
      'approved' => PaymentStatus.success,
      'refunded' => PaymentStatus.refunded,
      'rejected' || 'failed' || 'cancelled' => PaymentStatus.cancelled,
      _ => null,
    };
    if (settled != null) return settled;

    return booking == FinanceBookingState.cancelled
        ? PaymentStatus.cancelled
        : PaymentStatus.pending;
  }

  static RefundStatus refundStatus(String? raw) => switch (raw) {
    'approved' || 'settled' => RefundStatus.approved,
    'rejected' || 'failed' || 'cancelled' => RefundStatus.rejected,
    _ => RefundStatus.pending,
  };

  static SubscriptionStatus subscriptionStatus(String? raw) => switch (raw) {
    'expired' => SubscriptionStatus.expired,
    'cancelled' => SubscriptionStatus.cancelled,
    'pending_payment' || 'paused' => SubscriptionStatus.pendingPayment,
    _ => SubscriptionStatus.active,
  };

  static double toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;

  static int toInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
