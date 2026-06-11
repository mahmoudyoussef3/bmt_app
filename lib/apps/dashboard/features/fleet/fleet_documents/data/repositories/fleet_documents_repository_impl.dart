import 'dart:typed_data';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/data/datasources/fleet_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/data/datasources/supabase_fleet_datasource.dart';
import '../../domain/repositories/fleet_documents_repository.dart';

class FleetDocumentsRepositoryImpl implements FleetDocumentsRepository {
  final FleetDatasource _datasource;

  const FleetDocumentsRepositoryImpl(this._datasource);

  @override
  Future<List<FleetDocument>> getDocuments() async {
    try {
      final workspace = await _datasource.fetchWorkspace();
      return workspace.documents;
    } catch (e) {
      throw Exception('تعذر تحميل بيانات الوثائق: $e');
    }
  }

  @override
  Future<FleetDocument> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    try {
      return await _datasource.createDocument(
        ownerId: ownerId,
        isDriver: isDriver,
        type: type,
        fileUrl: fileUrl,
        expiryDate: expiryDate,
        status: status,
      );
    } catch (_) {
      throw Exception('تعذر حفظ الوثيقة');
    }
  }

  @override
  Future<FleetDocument> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    try {
      return await _datasource.updateDocument(
        documentId: documentId,
        isDriver: isDriver,
        fileUrl: fileUrl,
        expiryDate: expiryDate,
        status: status,
      );
    } catch (_) {
      throw Exception('تعذر تحديث الوثيقة');
    }
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    try {
      await _datasource.deleteDocument(
        documentId: documentId,
        isDriver: isDriver,
      );
    } catch (_) {
      throw Exception('تعذر حذف الوثيقة');
    }
  }

  @override
  Future<String> uploadFile(String bucket, String path, List<int> bytes) async {
    try {
      final datasource = _datasource;
      if (datasource is SupabaseFleetDatasource) {
        return await datasource.uploadFile(bucket, path, Uint8List.fromList(bytes));
      }
      throw Exception('رفع الملفات متاح فقط مع Supabase');
    } catch (e) {
      throw Exception('تعذر رفع الملف: $e');
    }
  }

  @override
  Future<void> deleteFile(String bucket, String path) async {
    try {
      final datasource = _datasource;
      if (datasource is SupabaseFleetDatasource) {
        await datasource.deleteFile(bucket, path);
      }
    } catch (_) {
      throw Exception('تعذر حذف الملف');
    }
  }
}
