import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification_draft.dart';

abstract class NotificationsDispatchDatasource {
  Future<void> insertForUser({
    required String userId,
    required NotificationDraft draft,
  });

  Future<int> broadcastRpc(NotificationDraft draft);
}

class SupabaseNotificationsDispatchDatasource
    implements NotificationsDispatchDatasource {
  const SupabaseNotificationsDispatchDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> insertForUser({
    required String userId,
    required NotificationDraft draft,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': draft.title,
      'body': draft.body,
      'category': draft.category.name,
      'target_app': draft.targetApp.name,
      'action_url': draft.actionUrl,
      'data': draft.data,
      'is_read': false,
    });
  }

  @override
  Future<int> broadcastRpc(NotificationDraft draft) async {
    // Broadcast fans out to every user of the target app and has no office
    // dimension, so it is gated on the platform-admin role rather than on
    // office membership. The raw RPC is no longer callable from the client tier.
    final result = await _client.rpc(
      'platform_broadcast_notification',
      params: {
        'p_title': draft.title,
        'p_body': draft.body,
        'p_category': draft.category.name,
        'p_target_app': draft.targetApp.name,
        'p_action_url': draft.actionUrl,
        'p_data': draft.data,
      },
    );
    return (result as int?) ?? 0;
  }
}
