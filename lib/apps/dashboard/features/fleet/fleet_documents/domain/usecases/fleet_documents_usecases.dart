import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import '../repositories/fleet_documents_repository.dart';

class GetFleetDocumentsUseCase {
  final FleetDocumentsRepository _repository;
  const GetFleetDocumentsUseCase(this._repository);
  Future<List<FleetDocument>> call() => _repository.getDocuments();
}

class CreateFleetDocumentUseCase {
  final FleetDocumentsRepository _repository;
  const CreateFleetDocumentUseCase(this._repository);
  Future<FleetDocument> call({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) => _repository.createDocument(
    ownerId: ownerId,
    isDriver: isDriver,
    type: type,
    fileUrl: fileUrl,
    expiryDate: expiryDate,
    status: status,
  );
}

class UpdateFleetDocumentUseCase {
  final FleetDocumentsRepository _repository;
  const UpdateFleetDocumentUseCase(this._repository);
  Future<FleetDocument> call({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) => _repository.updateDocument(
    documentId: documentId,
    isDriver: isDriver,
    fileUrl: fileUrl,
    expiryDate: expiryDate,
    status: status,
  );
}

class DeleteFleetDocumentUseCase {
  final FleetDocumentsRepository _repository;
  const DeleteFleetDocumentUseCase(this._repository);
  Future<void> call({required String documentId, required bool isDriver}) =>
      _repository.deleteDocument(documentId: documentId, isDriver: isDriver);
}

class UploadDocumentFileUseCase {
  final FleetDocumentsRepository _repository;
  const UploadDocumentFileUseCase(this._repository);
  Future<String> call(String bucket, String path, List<int> bytes) =>
      _repository.uploadFile(bucket, path, bytes);
}

class DeleteDocumentFileUseCase {
  final FleetDocumentsRepository _repository;
  const DeleteDocumentFileUseCase(this._repository);
  Future<void> call(String bucket, String path) =>
      _repository.deleteFile(bucket, path);
}
