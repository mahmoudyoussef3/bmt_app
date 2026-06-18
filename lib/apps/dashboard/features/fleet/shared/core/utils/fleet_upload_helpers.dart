import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

/// Shared file-upload helpers for the Fleet module.
///
/// Extracted from the original document manager so both the legacy manager and
/// the inline document section embedded in the create/edit forms reuse one
/// implementation instead of duplicating logic.
class FleetUploadHelpers {
  const FleetUploadHelpers._();

  /// Reads the bytes of a picked file on both web (in-memory) and native (path).
  static Future<List<int>?> readPickedFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (!kIsWeb && file.path != null) {
      return io.File(file.path!).readAsBytes();
    }
    return null;
  }

  /// Sanitizes a filename into a storage-safe slug while preserving extension.
  static String safeStorageFileName(String input) {
    final extension = input.contains('.') ? '.${input.split('.').last}' : '';
    final nameWithoutExtension = input.contains('.')
        ? input.substring(0, input.lastIndexOf('.'))
        : input;

    final safeName = nameWithoutExtension
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${safeName.isEmpty ? 'file' : safeName}$extension';
  }

  /// Extracts the storage object path from a Supabase public URL for deletion.
  static String? storagePathFromPublicUrl(String url, {required String bucket}) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(bucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return null;

    return segments.skip(bucketIndex + 1).join('/');
  }

  /// Opens the file picker for fleet documents (pdf/image) and returns the
  /// picked file together with its bytes, or null if cancelled/unreadable.
  /// Throws a localized message string when the file exceeds the 10MB limit.
  static Future<({PlatformFile file, List<int> bytes})?> pickDocumentFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = await readPickedFileBytes(file);

    if (bytes == null || bytes.isEmpty) {
      throw 'تعذر قراءة محتوى الملف. جرّب ملف آخر.';
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw 'حجم الملف كبير. الحد الأقصى 10MB.';
    }

    return (file: file, bytes: bytes);
  }
}
