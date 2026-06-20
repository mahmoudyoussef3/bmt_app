/// Static reference content for the settings/help surfaces.
///
/// FAQs and the legal table of contents are editorial help content rather than
/// operational data. They are kept here as English constants until a backend
/// CMS table (`app_faqs`, `app_legal_sections`) is provisioned — see
/// docs/CLIENT_APP_BUSINESS_FLOW.md for the required schema.
class SettingsStaticContent {
  const SettingsStaticContent._();

  static const List<Map<String, String>> faqs = [
    {
      'id': 'faq1',
      'category': 'Booking',
      'question': 'How do I cancel my reserved daily seat?',
      'answer':
          'You can release or cancel your seat from the Seat Release Center. '
          'Release requests must be submitted at least 12 hours before the '
          'trip\'s departure time.',
    },
    {
      'id': 'faq2',
      'category': 'Booking',
      'question': 'Can I change my pickup point during the trip?',
      'answer':
          'No. To keep the route optimized and on schedule, pickup and '
          'drop-off points cannot be changed after the trip has started.',
    },
    {
      'id': 'faq3',
      'category': 'Payments',
      'question': 'What payment methods are available?',
      'answer':
          'We support InstaPay, mobile wallets (Vodafone Cash, Orange Money, '
          'and others), and cash payment to the driver.',
    },
    {
      'id': 'faq4',
      'category': 'Packages',
      'question': 'How is a package subscription renewed?',
      'answer':
          'Your package stays active until its expiry date. If auto-renew is '
          'enabled, it renews automatically 24 hours before expiry.',
    },
    {
      'id': 'faq5',
      'category': 'Refunds',
      'question': 'When do I receive compensation for a released seat?',
      'answer':
          'Once another passenger books your released seat, the compensation '
          'is added to your wallet instantly.',
    },
    {
      'id': 'faq6',
      'category': 'Technical',
      'question': 'Why isn\'t the live tracking map updating?',
      'answer':
          'Make sure you have a stable internet connection and that location '
          'permissions are enabled. If the problem persists, restart the app.',
    },
  ];

  static const List<Map<String, dynamic>> termsTableOfContents = [
    {'title': '1. Introduction', 'progress': 0.1},
    {'title': '2. User Accounts & Registration', 'progress': 0.3},
    {'title': '3. Packages & Billing', 'progress': 0.55},
    {'title': '4. Seat Release & Cancellation Policy', 'progress': 0.75},
    {'title': '5. Fair Use & Code of Conduct', 'progress': 0.9},
  ];
}
