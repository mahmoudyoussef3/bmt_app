import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_documents/domain/usecases/fleet_documents_usecases.dart';
import 'fleet_documents_state.dart';

class FleetDocumentsCubit extends Cubit<FleetDocumentsState> {
  final GetFleetDocumentsUseCase _getDocuments;
  final CreateFleetDocumentUseCase _createDocument;
  final UpdateFleetDocumentUseCase _updateDocument;
  final DeleteFleetDocumentUseCase _deleteDocument;
  final UploadDocumentFileUseCase _uploadFile;
  final DeleteDocumentFileUseCase _deleteFile;

  FleetDocumentsCubit({
    required GetFleetDocumentsUseCase getDocuments,
    required CreateFleetDocumentUseCase createDocument,
    required UpdateFleetDocumentUseCase updateDocument,
    required DeleteFleetDocumentUseCase deleteDocument,
    required UploadDocumentFileUseCase uploadFile,
    required DeleteDocumentFileUseCase deleteFile,
  }) : _getDocuments = getDocuments,
       _createDocument = createDocument,
       _updateDocument = updateDocument,
       _deleteDocument = deleteDocument,
       _uploadFile = uploadFile,
       _deleteFile = deleteFile,
       super(const FleetDocumentsLoading());

  Future<void> load() async {
    emit(const FleetDocumentsLoading());
    try {
      final documents = await _getDocuments();
      debugPrint('[FleetDocumentsCubit] Loaded ${documents.length} documents');
      emit(FleetDocumentsLoaded(documents: documents));
    } catch (error) {
      debugPrint('[FleetDocumentsCubit] Error: $error');
      emit(FleetDocumentsError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! FleetDocumentsLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  void filter(String filter) {
    final current = state;
    if (current is! FleetDocumentsLoaded) return;
    emit(current.copyWith(filter: filter));
  }

  FleetDocumentStatus calculateDocumentStatus(String expiryDate) {
    try {
      final date = DateTime.tryParse(expiryDate);
      if (date != null) {
        final difference = date.difference(DateTime.now()).inDays;
        if (difference < 0) return FleetDocumentStatus.expired;
        if (difference <= 30) return FleetDocumentStatus.expiringSoon;
        return FleetDocumentStatus.valid;
      }
    } catch (_) {}
    return FleetDocumentStatus.valid;
  }

  Future<String?> saveDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    String? documentId,
  }) async {
    try {
      final status = calculateDocumentStatus(expiryDate);
      if (documentId == null || documentId.isEmpty) {
        debugPrint(
          '[FleetDocumentsCubit] Creating document for owner=$ownerId',
        );
        await _createDocument(
          ownerId: ownerId,
          isDriver: isDriver,
          type: type,
          fileUrl: fileUrl,
          expiryDate: expiryDate,
          status: status,
        );
      } else {
        debugPrint('[FleetDocumentsCubit] Updating document $documentId');
        await _updateDocument(
          documentId: documentId,
          isDriver: isDriver,
          fileUrl: fileUrl,
          expiryDate: expiryDate,
          status: status,
        );
      }
      await _reload();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    try {
      debugPrint('[FleetDocumentsCubit] Deleting document $documentId');
      await _deleteDocument(documentId: documentId, isDriver: isDriver);
      await _reload();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> uploadDocumentFile(
    String bucket,
    String path,
    List<int> bytes,
  ) async {
    try {
      debugPrint(
        '[FleetDocumentsCubit] Uploading file: bucket=$bucket path=$path',
      );
      return await _uploadFile(bucket, path, bytes);
    } catch (error) {
      debugPrint('[FleetDocumentsCubit] Upload error: $error');
      return null;
    }
  }

  Future<String?> deleteDocumentFile(String bucket, String path) async {
    try {
      await _deleteFile(bucket, path);
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> _reload() async {
    final current = state;
    try {
      final documents = await _getDocuments();
      if (current is FleetDocumentsLoaded) {
        emit(current.copyWith(documents: documents));
      } else {
        emit(FleetDocumentsLoaded(documents: documents));
      }
    } catch (error) {
      emit(FleetDocumentsError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}
