import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Where a tapped push should land: a route name and the arguments that route
/// needs. Each app supplies its own resolver, so this file stays free of any
/// app's route table.
typedef PushDestination = ({String route, Object? arguments});
typedef PushDestinationResolver =
    PushDestination? Function(Map<String, dynamic> data);

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _userId;
  String? _appType;
  PushDestinationResolver? _resolveDestination;
  bool _initialized = false;

  /// Call once after the user authenticates.
  /// [appType] is 'client' | 'captain' | 'dashboard'
  ///
  /// [resolveDestination] turns a push payload into a screen. Without it a tap
  /// falls back to pushing `data['action_url']` verbatim — which is what every
  /// app did before, and which lands on the wrong record whenever the route
  /// needs an id (Trip Details with no argument opens the newest booking, not
  /// the one the push named).
  Future<void> initialize({
    required String userId,
    required String appType,
    required SupabaseClient supabase,
    required GlobalKey<NavigatorState> navigatorKey,
    PushDestinationResolver? resolveDestination,
  }) async {
    if (_initialized && _userId == userId) return;
    _userId = userId;
    _appType = appType;
    _navigatorKey = navigatorKey;
    _resolveDestination = resolveDestination;
    _initialized = true;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
    }
    if (token != null) await _saveToken(supabase, token);

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (t) => _saveToken(supabase, t),
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial);
  }

  Future<void> _saveToken(SupabaseClient supabase, String token) async {
    final uid = _userId;
    final type = _appType;
    if (uid == null || type == null) return;
    try {
      await supabase.from('notification_tokens').upsert(
        {
          'user_id': uid,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app_type': type,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
    } catch (_) {}
  }

  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null) return;
    final title = n.title ?? '';
    final body = n.body ?? '';
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(fontSize: 13)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: ctx.l10n.common_view,
          onPressed: () => _onTap(message),
        ),
      ),
    );
  }

  void _onTap(RemoteMessage message) {
    final destination = _resolveDestination?.call(message.data);
    if (destination != null) {
      _navigatorKey?.currentState?.pushNamed(
        destination.route,
        arguments: destination.arguments,
      );
      return;
    }

    final url = message.data['action_url'] as String?;
    if (url != null && url.isNotEmpty) {
      _navigatorKey?.currentState?.pushNamed(url);
    }
  }

  /// Call on logout — marks the current device token inactive.
  Future<void> deactivateToken(SupabaseClient supabase) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await supabase
            .from('notification_tokens')
            .update({'is_active': false})
            .eq('user_id', uid)
            .eq('token', token);
      }
    } catch (_) {}
    _userId = null;
    _appType = null;
    _navigatorKey = null;
    _initialized = false;
  }
}
