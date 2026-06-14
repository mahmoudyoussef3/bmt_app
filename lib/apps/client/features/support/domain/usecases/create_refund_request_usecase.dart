import 'dart:io';
import '../repositories/support_repository.dart';
import '../entities/support_refund_request.dart';

class CreateRefundRequestUseCase {
  final SupportRepository _repository;

  const CreateRefundRequestUseCase(this._repository);

  Future<SupportRefundRequest> call({
    required String reason,
    String? description,
    required double amount,
    String? bookingId,
    String? tripId,
    File? evidenceFile,
  }) {
    return _repository.createRefundRequest(
      reason: reason,
      description: description,
      amount: amount,
      bookingId: bookingId,
      tripId: tripId,
      evidenceFile: evidenceFile,
    );
  }
}
