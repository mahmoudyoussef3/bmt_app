import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/operational_alert_model.dart';

/// Reads the shared `operational_alerts` feed. The Dashboard runs as the anon
/// role (single-owner, no login), so — like the other operational tables — the
/// feed has RLS disabled and every operator sees the same queue.
abstract class OperationalAlertsDatasource {
  Stream<List<OperationalAlertModel>> watchAlerts();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class SupabaseOperationalAlertsDatasource
    implements OperationalAlertsDatasource {
  const SupabaseOperationalAlertsDatasource(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<OperationalAlertModel>> watchAlerts() {
    return _client
        .from('operational_alerts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((rows) => rows.map(OperationalAlertModel.fromMap).toList());
  }

  @override
  Stream<int> watchUnreadCount() {
    return _client
        .from('operational_alerts')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows.where((r) => !(r['is_read'] as bool? ?? false)).length,
        );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client
        .from('operational_alerts')
        .update({'is_read': true})
        .eq('id', id);
  }

  @override
  Future<void> markAllAsRead() async {
    await _client
        .from('operational_alerts')
        .update({'is_read': true})
        .eq('is_read', false);
  }
}
