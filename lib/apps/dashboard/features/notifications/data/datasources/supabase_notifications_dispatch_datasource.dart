import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
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

  /// Sends one notification through `office_dispatch_notification`.
  ///
  /// This used to be a direct `insert` into `notifications` under the
  /// `notifications_staff_insert` policy — which let any office user address any
  /// user id on the platform, with no office scoping and no licensing at all.
  /// The policy is gone; the RPC is the only path, and it enforces three things
  /// the insert never could: the `push_notifications` entitlement, that the
  /// recipient actually belongs to this office, and that the office is not in a
  /// read-only licence state.
  @override
  Future<void> insertForUser({
    required String userId,
    required NotificationDraft draft,
  }) async {
    await LicensingGuard.run(
      () => _client.rpc(
        'office_dispatch_notification',
        params: {
          'p_user_id': userId,
          'p_title': draft.title,
          'p_body': draft.body,
          'p_category': draft.category.name,
          'p_target_app': draft.targetApp.name,
          'p_action_url': draft.actionUrl,
          'p_data': draft.data,
        },
      ),
    );
  }

  @override
  Future<int> broadcastRpc(NotificationDraft draft) async {
    
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
