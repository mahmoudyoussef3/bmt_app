import 'dart:typed_data';

import '../repositories/payment_repository.dart';

class UploadPaymentReceiptUseCase {
  const UploadPaymentReceiptUseCase(this._repository);

  final PaymentRepository _repository;

  Future<String> call({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) {
    return _repository.uploadReceipt(
      bookingOrTripId: bookingOrTripId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
