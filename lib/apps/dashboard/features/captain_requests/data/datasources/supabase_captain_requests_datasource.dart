import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/captain_request_model.dart';

class SupabaseCaptainRequestsDatasource {
  final SupabaseClient _client;
  static const String _table = 'captain_requests';

  const SupabaseCaptainRequestsDatasource(this._client);

  Future<List<CaptainRequestModel>> getRequests() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return rows
        .map((e) => CaptainRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Stream<List<CaptainRequestModel>> watchRequests() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (e) => CaptainRequestModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
        );
  }

  Future<void> approve({
    required String requestId,
    required String driverId,
  }) async {
    await _client
        .from(_table)
        .update({
          'status': 'approved',
          'driver_id': driverId,
          'reviewed_by': _client.auth.currentUser?.id,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> reject({
    required String requestId,
    required String reason,
  }) async {
    await _client
        .from(_table)
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'reviewed_by': _client.auth.currentUser?.id,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }
}
