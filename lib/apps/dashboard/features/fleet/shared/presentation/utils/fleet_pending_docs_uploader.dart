import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_upload_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';

/// Uploads queued [PendingFleetDocument]s for a freshly-saved driver/vehicle.
///
/// Reuses [FleetDocumentsCubit]'s upload + persist pipeline so the create/edit
/// forms don't duplicate storage logic. Returns the labels of any documents
/// that failed, so the caller can surface a non-fatal warning (the owning
/// entity is already saved at this point).
class FleetPendingDocsUploader {
  const FleetPendingDocsUploader._();

  static Future<List<String>> upload(
    FleetDocumentsCubit cubit, {
    required String ownerId,
    required bool isDriver,
    required List<PendingFleetDocument> docs,
  }) async {
    final failed = <String>[];
    final ownerFolder = isDriver ? 'drivers' : 'vehicles';

    for (final doc in docs) {
      try {
        final typeFolder = doc.type.wireName;
        final fileName = FleetUploadHelpers.safeStorageFileName(doc.fileName);
        final path =
            '$ownerFolder/$ownerId/$typeFolder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final url = await cubit.uploadDocumentFile(
          'documents',
          path,
          doc.bytes,
        );
        if (url == null || url.isEmpty) {
          failed.add(doc.type.label);
          continue;
        }

        final err = await cubit.saveDocument(
          ownerId: ownerId,
          isDriver: isDriver,
          type: doc.type,
          fileUrl: url,
          expiryDate: doc.expiryDate,
        );
        if (err != null) failed.add(doc.type.label);
      } catch (_) {
        failed.add(doc.type.label);
      }
    }

    return failed;
  }
}
