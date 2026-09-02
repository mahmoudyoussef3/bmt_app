/// A prospective captain's self-service access request awaiting review.
library;

enum CaptainRequestStatus {
  /// «بانتظار القرار», not «قيد المراجعة»: the queue tab, the KPI tile and this
  /// badge all name the same set of rows, and the module read as two different
  /// vocabularies while they disagreed.
  pending('بانتظار القرار'),
  approved('مقبول'),
  rejected('مرفوض');

  final String label;
  const CaptainRequestStatus(this.label);

  static CaptainRequestStatus fromDb(String value) => switch (value) {
    'approved' => CaptainRequestStatus.approved,
    'rejected' => CaptainRequestStatus.rejected,
    _ => CaptainRequestStatus.pending,
  };
}

class CaptainRequest {
  final String id;
  final String fullName;
  final String phone;
  final CaptainRequestStatus status;
  final String? note;
  final String? rejectionReason;
  final String? driverId;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const CaptainRequest({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.note,
    this.rejectionReason,
    this.driverId,
    this.reviewedAt,
  });

  bool get isPending => status == CaptainRequestStatus.pending;
}
