import '../../domain/entities/support_refund_request.dart';

class SupportRefundRequestModel extends SupportRefundRequest {
  const SupportRefundRequestModel({
    required super.id,
    required super.clientId,
    super.ticketId,
    super.bookingId,
    super.tripId,
    required super.reason,
    super.description,
    required super.amount,
    required super.currency,
    required super.status,
    super.evidenceUrl,
    super.reviewedBy,
    super.reviewedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportRefundRequestModel.fromJson(Map<String, dynamic> json) {
    return SupportRefundRequestModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      ticketId: json['ticket_id'] as String?,
      bookingId: json['booking_id'] as String?,
      tripId: json['trip_id'] as String?,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: _parseRefundStatus(json['status'] as String?),
      evidenceUrl: json['evidence_url'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static RefundStatus _parseRefundStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return RefundStatus.approved;
      case 'rejected':
        return RefundStatus.rejected;
      case 'processed':
        return RefundStatus.processed;
      case 'pending':
      default:
        return RefundStatus.pending;
    }
  }
}
