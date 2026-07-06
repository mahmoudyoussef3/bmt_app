import '../../domain/entities/captain_request.dart';
import '../../domain/repositories/captain_requests_repository.dart';
import '../datasources/supabase_captain_requests_datasource.dart';

class CaptainRequestsRepositoryImpl implements CaptainRequestsRepository {
  final SupabaseCaptainRequestsDatasource _datasource;

  const CaptainRequestsRepositoryImpl(this._datasource);

  @override
  Future<List<CaptainRequest>> getRequests() async {
    try {
      return await _datasource.getRequests();
    } catch (e) {
      throw Exception('تعذر تحميل طلبات الكباتن: $e');
    }
  }

  @override
  Stream<List<CaptainRequest>> watchRequests() => _datasource.watchRequests();

  @override
  Future<void> approve({
    required String requestId,
    required String driverId,
  }) async {
    try {
      await _datasource.approve(requestId: requestId, driverId: driverId);
    } catch (e) {
      throw Exception('تعذر ربط الطلب بالسائق: $e');
    }
  }

  @override
  Future<void> reject({
    required String requestId,
    required String reason,
  }) async {
    try {
      await _datasource.reject(requestId: requestId, reason: reason);
    } catch (e) {
      throw Exception('تعذر رفض الطلب: $e');
    }
  }
}
