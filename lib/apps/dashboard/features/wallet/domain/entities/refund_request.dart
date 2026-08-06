import 'wallet_vocabulary.dart';

/// The authoritative record of ONE refund decision, whatever its destination.
///
/// Not a wallet operation (§2.3): offices refund to InstaPay, to a card via
/// Paymob, and in cash, and those refunds never touch the wallet. Only
/// [settlement] == [RefundSettlement.wallet] also posts a ledger entry, linked
/// both ways through [walletTransactionId].
///
/// The client-initiated request and the office-initiated refund are the same
/// record at different stages — one pipeline, one audit trail, one queue.
class RefundRequest {
  final String id;
  final String? clientId;
  final String? clientName;
  final String? clientPhone;
  final String? bookingId;
  final String? bookingNumber;
  final String? tripId;

  /// What was asked for.
  final double amount;

  /// What was actually decided. Null until the decision is made; every settled
  /// refund has one, which is what makes the revenue query trustworthy.
  final double? approvedAmount;

  final String currency;
  final RefundStatus status;
  final String category;
  final String reason;
  final String? notes;

  /// `client` or `dashboard` — which side filed it.
  final String source;

  final RefundSettlement? settlement;
  final DateTime? settledAt;
  final String? walletTransactionId;
  final String? externalTransactionId;

  /// Stamps every refund produced by one cancelled-trip batch, so the operator
  /// can see, verify and if necessary reverse the batch as a unit (§9.4).
  final String? batchId;

  final String? requestedByName;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const RefundRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.category,
    required this.reason,
    required this.source,
    required this.createdAt,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.bookingId,
    this.bookingNumber,
    this.tripId,
    this.approvedAmount,
    this.notes,
    this.settlement,
    this.settledAt,
    this.walletTransactionId,
    this.externalTransactionId,
    this.batchId,
    this.requestedByName,
    this.reviewedByName,
    this.reviewedAt,
  });

  /// The number that matters on screen: what was decided if a decision exists,
  /// otherwise what was asked for.
  double get effectiveAmount => approvedAmount ?? amount;

  bool get isOpen => status.isOpen;
  bool get fromClient => source == 'client';
  String get categoryLabel => WalletCategories.labelOf(category);
}

/// A booking this customer holds that still has refundable value.
///
/// [refundableAmount] comes from the server's `refund_capacity`, never from a
/// Dart reimplementation of the rule: a second definition of "how much is left"
/// is a second definition that can drift.
class RefundableBooking {
  final String bookingId;
  final String? bookingNumber;
  final String? tripId;
  final DateTime? tripDate;
  final String? route;
  final String? seat;
  final String status;
  final String? paymentMethod;
  final double paidAmount;
  final double refundableAmount;
  final DateTime? createdAt;

  const RefundableBooking({
    required this.bookingId,
    required this.status,
    required this.paidAmount,
    required this.refundableAmount,
    this.bookingNumber,
    this.tripId,
    this.tripDate,
    this.route,
    this.seat,
    this.paymentMethod,
    this.createdAt,
  });

  String get label =>
      bookingNumber?.trim().isNotEmpty == true ? '#${bookingNumber!}' : '—';
}

/// A cancelled trip that still owes its passengers money (§9.4).
class CancelledTripRefundTarget {
  final String tripId;
  final DateTime? tripDate;
  final String? departureTime;
  final String? routeName;
  final int pendingBookings;
  final double refundableAmount;

  const CancelledTripRefundTarget({
    required this.tripId,
    required this.pendingBookings,
    required this.refundableAmount,
    this.tripDate,
    this.departureTime,
    this.routeName,
  });
}

/// What one batch run did. Reported back rather than silently summarised,
/// because "14 seats, 12 refunded, 2 already settled" is the answer the operator
/// needs before they close the screen.
class TripBatchRefundResult {
  final String batchId;
  final String tripId;
  final int refunded;
  final int skipped;
  final double totalAmount;

  const TripBatchRefundResult({
    required this.batchId,
    required this.tripId,
    required this.refunded,
    required this.skipped,
    required this.totalAmount,
  });
}
