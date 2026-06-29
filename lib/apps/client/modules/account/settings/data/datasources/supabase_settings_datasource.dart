import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/settings_data.dart';
import 'settings_static_content.dart';

abstract class SettingsDatasource {
  Future<SettingsData> getSettingsData();
}

class SupabaseSettingsDatasource implements SettingsDatasource {
  const SupabaseSettingsDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<SettingsData> getSettingsData() async {
    final user = _client.auth.currentUser;
    if (user == null) return _defaultSettings();

    final profile = await _client
        .from('clients')
        .select('full_name, phone, email')
        .eq('id', user.id)
        .maybeSingle();

    final meta = user.userMetadata ?? {};

    return SettingsData(
      selectedLanguage: meta['language'] as String? ?? 'en',
      selectedTheme: meta['theme'] as String? ?? 'system',
      userName:
          profile?['full_name'] as String? ??
          meta['full_name'] as String? ??
          '',
      userEmail: profile?['email'] as String? ?? user.email ?? '',
      userPhone: profile?['phone'] as String? ?? '',
      activeSessions: _currentSession(),
      notificationsSettings: _extractNotificationSettings(meta),
      faqs: SettingsStaticContent.faqs,
      termsTableOfContents: SettingsStaticContent.termsTableOfContents,
    );
  }

  /// Only the live session is known to the client. Cross-device session
  /// management requires a backend `user_sessions` table (documented in
  /// docs/CLIENT_APP_BUSINESS_FLOW.md); until then we surface the real
  /// authenticated session rather than fabricated devices.
  List<Map<String, String>> _currentSession() => const [
    {
      'id': 'current',
      'device': 'This device',
      'platform': 'Mobile app',
      'time': 'Active now',
      'current': 'true',
    },
  ];

  Map<String, Map<String, bool>> _extractNotificationSettings(
    Map<String, dynamic> meta,
  ) {
    final raw = meta['notification_settings'];
    if (raw is Map) {
      try {
        return (raw as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>).map(
              (k2, v2) => MapEntry(k2, v2 as bool? ?? true),
            ),
          ),
        );
      } catch (_) {}
    }
    return _defaultNotificationSettings();
  }

  Map<String, Map<String, bool>> _defaultNotificationSettings() => {
    'trips': {'push': true, 'sms': true, 'email': false},
    'payments': {'push': true, 'sms': false, 'email': true},
    'packages': {'push': true, 'sms': true, 'email': true},
    'promotions': {'push': false, 'sms': false, 'email': false},
    'support': {'push': true, 'sms': true, 'email': true},
  };

  SettingsData _defaultSettings() {
    return SettingsData(
      selectedLanguage: 'en',
      selectedTheme: 'system',
      userName: '',
      userEmail: '',
      userPhone: '',
      activeSessions: const [],
      notificationsSettings: _defaultNotificationSettings(),
      faqs: SettingsStaticContent.faqs,
      termsTableOfContents: SettingsStaticContent.termsTableOfContents,
    );
  }
}
