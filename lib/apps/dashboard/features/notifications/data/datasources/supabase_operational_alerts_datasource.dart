import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/operational_alert_model.dart';

/// Reads the `operational_alerts` feed. Scoping is the server's: RLS narrows
/// the table to the signed-in operator's office, so every query here is written
/// as if it were unscoped and comes back scoped.
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

  /// The bell badge, counted by the server rather than by holding the feed.
  ///
  /// This subscription is open for the whole session — the bell lives in the
  /// shell — so the previous shape, an unfiltered `.stream()` counted in Dart,
  /// pulled the office's entire alert history into memory on every sign-in and
  /// grew with every alert ever raised. Counting server-side keeps the badge
  /// exact (it still counts *all* unread, not a page of them) while the client
  /// holds nothing, and `operational_alerts (office_id, created_at desc) where
  /// is_read = false` is indexed for precisely this query.
  ///
  /// The feed stream is the change signal because it is already bounded to 100
  /// rows; a second unbounded subscription to the same table is what this
  /// replaced.
  @override
  Stream<int> watchUnreadCount() {
    return watchAlerts().asyncMap((_) => _unreadCount());
  }

  Future<int> _unreadCount() async {
    final response = await _client
        .from('operational_alerts')
        .select('id')
        .eq('is_read', false)
        .count(CountOption.exact);
    return response.count;
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
