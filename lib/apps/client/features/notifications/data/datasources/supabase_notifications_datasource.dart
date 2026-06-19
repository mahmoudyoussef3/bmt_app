import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_notification_model.dart';

class SupabaseNotificationsDatasource {
  const SupabaseNotificationsDatasource(this._client);

  final SupabaseClient _client;

  Future<List<ClientNotificationModel>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('notifications')
        .select('id, title, body, type, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((r) => ClientNotificationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
