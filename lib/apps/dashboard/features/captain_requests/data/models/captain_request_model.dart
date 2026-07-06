import '../../domain/entities/captain_request.dart';

class CaptainRequestModel extends CaptainRequest {
  const CaptainRequestModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.status,
    required super.createdAt,
    super.note,
    super.rejectionReason,
    super.driverId,
    super.reviewedAt,
  });

  factory CaptainRequestModel.fromJson(Map<String, dynamic> json) {
    return CaptainRequestModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: CaptainRequestStatus.fromDb(json['status'] as String? ?? 'pending'),
      note: json['note'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      driverId: json['driver_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    );
  }
}
