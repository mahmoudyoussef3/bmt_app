enum RefundStatus { pending, approved, rejected, processed }

class SupportRefundRequest {
  const SupportRefundRequest({
    required this.id,
    required this.clientId,
    this.ticketId,
    this.bookingId,
    this.tripId,
    required this.reason,
    this.description,
    required this.amount,
    required this.currency,
    required this.status,
    this.evidenceUrl,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String? ticketId;
  final String? bookingId;
  final String? tripId;
  final String reason;
  final String? description;
  final double amount;
  final String currency;
  final RefundStatus status;
  final String? evidenceUrl;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
