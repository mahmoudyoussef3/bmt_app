import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';

/// Repository contract for fleet document operations.
abstract class FleetDocumentsRepository {
  Future<List<FleetDocument>> getDocuments();
  Future<FleetDocument> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  });
  Future<FleetDocument> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  });
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  });
  Future<String> uploadFile(String bucket, String path, List<int> bytes);
  Future<void> deleteFile(String bucket, String path);
}
