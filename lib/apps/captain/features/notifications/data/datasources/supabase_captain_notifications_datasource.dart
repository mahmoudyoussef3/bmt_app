import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/captain_notification_model.dart';

abstract class CaptainNotificationsDatasource {
  Future<List<CaptainNotificationModel>> getNotifications();
  Stream<List<CaptainNotificationModel>> watchNotifications();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class SupabaseCaptainNotificationsDatasource
    implements CaptainNotificationsDatasource {
  const SupabaseCaptainNotificationsDatasource(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<List<CaptainNotificationModel>> getNotifications() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .inFilter('target_app', ['captain', 'all'])
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(CaptainNotificationModel.fromMap).toList();
  }

  @override
  Stream<List<CaptainNotificationModel>> watchNotifications() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) {
                final app = r['target_app'] as String? ?? 'client';
                return app == 'captain' || app == 'all';
              })
              .map(CaptainNotificationModel.fromMap)
              .toList(),
        );
  }

  @override
  Stream<int> watchUnreadCount() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .map(
          (rows) => rows.where((r) {
            final app = r['target_app'] as String? ?? 'client';
            final unread = !(r['is_read'] as bool? ?? false);
            return unread && (app == 'captain' || app == 'all');
          }).length,
        );
  }

  @override
  Future<void> markAsRead(String id) async =>
      _client.from('notifications').update({'is_read': true}).eq('id', id);

  @override
  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }
}
