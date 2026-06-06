import '../../domain/entities/settings_data.dart';

class MockSettingsDatasource {
  const MockSettingsDatasource();

  Future<SettingsData> getSettingsData() async {
    return SettingsData(
      selectedLanguage: 'en',
      selectedTheme: 'system',
      userName: 'Ahmed Hassan',
      userEmail: 'ahmed.hassan@example.com',
      userPhone: '+20 10 1234 5678',
      activeSessions: const [
        {
          'id': 's1',
          'device': 'iPhone 15 Pro',
          'platform': 'iOS App',
          'time': 'Active Now (This Device)',
          'current': 'true',
        },
        {
          'id': 's2',
          'device': 'MacBook Pro 16"',
          'platform': 'macOS Chrome',
          'time': '2 hours ago',
          'current': 'false',
        },
        {
          'id': 's3',
          'device': 'iPad Pro',
          'platform': 'iPadOS App',
          'time': '3 days ago',
          'current': 'false',
        },
        {
          'id': 's4',
          'device': 'Windows Desktop',
          'platform': 'Windows Firefox',
          'time': 'May 28, 2026',
          'current': 'false',
        },
      ],
      notificationsSettings: {
        'trips': {'push': true, 'sms': true, 'email': false},
        'payments': {'push': true, 'sms': false, 'email': true},
        'packages': {'push': true, 'sms': true, 'email': true},
        'promotions': {'push': false, 'sms': false, 'email': false},
        'support': {'push': true, 'sms': true, 'email': true},
      },
      faqs: const [
        {
          'id': 'faq1',
          'category': 'Booking',
          'question': 'How do I cancel my daily reserved seat?',
          'answer':
              'You can release or cancel your seat from the Seat Release Hub. Seat release requests must be submitted at least 12 hours before the trip departure time.',
        },
        {
          'id': 'faq2',
          'category': 'Booking',
          'question': 'Can I change my pickup location mid-trip?',
          'answer':
              'No, to ensure route optimization and timely arrivals for all passengers, pickup and dropoff locations cannot be changed once the ride starts.',
        },
        {
          'id': 'faq3',
          'category': 'Payments',
          'question': 'What payment methods do you support?',
          'answer':
              'We support major credit cards (Visa, MasterCard), InstaPay transfers, Mobile Wallets (Vodafone Cash, Orange Money, etc.), and Cash payment to the driver.',
        },
        {
          'id': 'faq4',
          'category': 'Packages',
          'question': 'How does package subscription renewal work?',
          'answer':
              'Your package remains active until the end date. If you have auto-renewal enabled, it will renew 24 hours prior to expiration using your preferred payment method.',
        },
        {
          'id': 'faq5',
          'category': 'Refunds',
          'question': 'When will I receive my rebooked seat compensation?',
          'answer':
              'If another passenger books your released seat, compensation is instantly credited to your wallet in the form of wallet credits, cashback, or loyalty points.',
        },
        {
          'id': 'faq6',
          'category': 'Technical Issues',
          'question': 'Why is my live trip tracking map not updating?',
          'answer':
              'Please verify that your device has a stable internet connection and location permissions are enabled. If issues persist, try restarting the application.',
        },
      ],
      termsTableOfContents: const [
        {'title': '1. Introduction', 'progress': 0.1},
        {'title': '2. User Accounts & Registration', 'progress': 0.3},
        {'title': '3. Subscription Packages & Billing', 'progress': 0.55},
        {'title': '4. Seat Release & Cancellation Policy', 'progress': 0.75},
        {'title': '5. Fair Use & Code of Conduct', 'progress': 0.9},
      ],
    );
  }
}
