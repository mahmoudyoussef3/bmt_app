import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/upload_payment_receipt_usecase.dart';

const int _maxReceiptBytes = 8 * 1024 * 1024;

/// Picks a transfer receipt and uploads it, returning the stored URL.
///
/// Returns null when the rider closes the picker without choosing anything —
/// backing out is not a failure and must not surface as an error.
Future<String?> pickAndUploadReceipt({required String bookingOrTripId}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    withData: true,
  );
  final picked = result?.files.single;
  if (picked == null) return null;

  if (picked.size > _maxReceiptBytes) {
    throw Exception('Receipts must be 8 MB or smaller.');
  }

  final bytes =
      picked.bytes ??
      (picked.path == null ? null : await File(picked.path!).readAsBytes());
  if (bytes == null || bytes.isEmpty) {
    throw Exception('That file could not be read. Try another one.');
  }

  return clientGetIt<UploadPaymentReceiptUseCase>()(
    bookingOrTripId: bookingOrTripId,
    fileName: picked.name,
    bytes: bytes,
    contentType: _contentTypeFor(picked.extension),
  );
}

String _contentTypeFor(String? extension) => switch (extension?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'pdf' => 'application/pdf',
  _ => 'application/octet-stream',
};
