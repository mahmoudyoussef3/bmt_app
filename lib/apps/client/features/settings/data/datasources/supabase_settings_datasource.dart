import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/settings_data.dart';

class SupabaseSettingsDatasource {
  const SupabaseSettingsDatasource(this._client);

  final SupabaseClient _client;

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
      selectedLanguage: meta['language'] as String? ?? 'ar',
      selectedTheme: meta['theme'] as String? ?? 'system',
      userName: profile?['full_name'] as String? ??
          meta['full_name'] as String? ??
          '',
      userEmail: profile?['email'] as String? ?? user.email ?? '',
      userPhone: profile?['phone'] as String? ?? '',
      activeSessions: [
        {
          'id': 'current',
          'device': 'الجهاز الحالي',
          'platform': 'تطبيق الهاتف',
          'time': 'نشط الآن',
          'current': 'true',
        },
      ],
      notificationsSettings: _extractNotificationSettings(meta),
      faqs: _staticFaqs,
      termsTableOfContents: _staticTermsToc,
    );
  }

  Map<String, Map<String, bool>> _extractNotificationSettings(
      Map<String, dynamic> meta) {
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
    return {
      'trips': {'push': true, 'sms': true, 'email': false},
      'payments': {'push': true, 'sms': false, 'email': true},
      'packages': {'push': true, 'sms': true, 'email': true},
      'promotions': {'push': false, 'sms': false, 'email': false},
      'support': {'push': true, 'sms': true, 'email': true},
    };
  }

  SettingsData _defaultSettings() {
    return SettingsData(
      selectedLanguage: 'ar',
      selectedTheme: 'system',
      userName: '',
      userEmail: '',
      userPhone: '',
      activeSessions: const [],
      notificationsSettings: {
        'trips': {'push': true, 'sms': true, 'email': false},
        'payments': {'push': true, 'sms': false, 'email': true},
        'packages': {'push': true, 'sms': true, 'email': true},
        'promotions': {'push': false, 'sms': false, 'email': false},
        'support': {'push': true, 'sms': true, 'email': true},
      },
      faqs: _staticFaqs,
      termsTableOfContents: _staticTermsToc,
    );
  }

  static const List<Map<String, String>> _staticFaqs = [
    {
      'id': 'faq1',
      'category': 'الحجز',
      'question': 'كيف يمكنني إلغاء مقعدي اليومي المحجوز؟',
      'answer':
          'يمكنك تحرير أو إلغاء مقعدك من مركز تحرير المقاعد. يجب تقديم طلبات التحرير قبل 12 ساعة على الأقل من وقت مغادرة الرحلة.',
    },
    {
      'id': 'faq2',
      'category': 'الحجز',
      'question': 'هل يمكنني تغيير نقطة الالتقاء أثناء الرحلة؟',
      'answer':
          'لا، لضمان تحسين المسار والالتزام بالمواعيد، لا يمكن تغيير نقاط الصعود والنزول بعد بدء الرحلة.',
    },
    {
      'id': 'faq3',
      'category': 'المدفوعات',
      'question': 'ما طرق الدفع المتاحة؟',
      'answer':
          'ندعم InstaPay والمحافظ الإلكترونية (فودافون كاش، أورنج موني...) والدفع نقداً للسائق.',
    },
    {
      'id': 'faq4',
      'category': 'الباقات',
      'question': 'كيف يتم تجديد اشتراك الباقة؟',
      'answer':
          'تظل باقتك نشطة حتى تاريخ انتهائها. في حال تفعيل التجديد التلقائي، يتم التجديد قبل 24 ساعة من الانتهاء.',
    },
    {
      'id': 'faq5',
      'category': 'الاسترداد',
      'question': 'متى أستلم التعويض عند تحرير مقعدي؟',
      'answer':
          'عند حجز راكب آخر لمقعدك المُحرَّر، يُضاف التعويض فوراً إلى محفظتك.',
    },
    {
      'id': 'faq6',
      'category': 'مشاكل تقنية',
      'question': 'لماذا لا تتحدث خريطة تتبع الرحلة المباشرة؟',
      'answer':
          'تأكد من وجود اتصال إنترنت مستقر وتفعيل صلاحيات الموقع. إذا استمرت المشكلة، أعد تشغيل التطبيق.',
    },
  ];

  static const List<Map<String, dynamic>> _staticTermsToc = [
    {'title': '١. مقدمة', 'progress': 0.1},
    {'title': '٢. حسابات المستخدمين والتسجيل', 'progress': 0.3},
    {'title': '٣. الباقات والفوترة', 'progress': 0.55},
    {'title': '٤. سياسة تحرير المقاعد والإلغاء', 'progress': 0.75},
    {'title': '٥. الاستخدام العادل وقواعد السلوك', 'progress': 0.9},
  ];
}
