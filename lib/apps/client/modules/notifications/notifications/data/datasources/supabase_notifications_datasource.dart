import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_notification_model.dart';

abstract class NotificationsDatasource {
  Future<List<ClientNotificationModel>> getNotifications();
  Stream<List<ClientNotificationModel>> watchNotifications();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class SupabaseNotificationsDatasource implements NotificationsDatasource {
  const SupabaseNotificationsDatasource(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<List<ClientNotificationModel>> getNotifications() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(ClientNotificationModel.fromMap).toList();
  }

  @override
  Stream<List<ClientNotificationModel>> watchNotifications() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(ClientNotificationModel.fromMap).toList());
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
          (rows) => rows.where((r) => !(r['is_read'] as bool? ?? false)).length,
        );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

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
