import '../../domain/entities/legal_document_data.dart';

/// The Terms and Privacy text the app ships with.
///
/// This is editorial content, not operational data: it is versioned with the
/// build precisely so a rider who is offline can still read what they agreed
/// to. When Legal needs to publish without a release, this moves behind an
/// `app_legal_documents` table and the datasource fetches it instead.
abstract final class LegalContent {
  const LegalContent._();

  /// Bump whenever the wording below changes materially.
  static final DateTime lastUpdated = DateTime(2026, 6, 3);

  static const List<LegalSection> terms = [
    LegalSection(
      title: 'Introduction',
      body:
          'By subscribing to or using our transportation platform and package '
          'booking options, you confirm that you have read, understood, and '
          'agreed to these Terms of Service. If you do not accept them, please '
          'stop using the service.',
    ),
    LegalSection(
      title: 'Accounts and registration',
      body:
          'You must register with a valid phone number and full name. You are '
          'responsible for everything done through your account. If you suspect '
          'your account has been accessed by someone else, contact support '
          'immediately.',
    ),
    LegalSection(
      title: 'Packages and billing',
      body:
          'Packages are sold weekly, monthly, or quarterly and guarantee a '
          'reserved seat on the route you chose. Payment is taken upfront. '
          'Packages are non-refundable, but they do allow you to release seats '
          'you will not use.',
    ),
    LegalSection(
      title: 'Seat release and cancellation',
      body:
          'A seat can be released up to 12 hours before departure. If another '
          'passenger books the seat you released, the compensation is credited '
          'to you. Releases inside the 12-hour window may be partly or fully '
          'forfeited.',
    ),
    LegalSection(
      title: 'Conduct on board',
      body:
          'We do not tolerate harassment, misconduct, or damage to the vehicle. '
          'Drivers may refuse to carry a passenger who breaks these rules, and '
          'no refund is due in that case.',
    ),
  ];

  static const List<LegalSection> privacy = [
    LegalSection(
      title: 'What we collect',
      body:
          'Your phone number, name, email, payment records, and — only while a '
          'trip is running — your device location, so we can show you where the '
          'vehicle is and confirm the trip took place.',
    ),
    LegalSection(
      title: 'How we use it',
      body:
          'To plan and adjust routes, confirm that a package is valid, pay out '
          'seat-release compensation, and notify you about your trips. We do '
          'not sell your data.',
    ),
    LegalSection(
      title: 'How we protect it',
      body:
          'Accounts, passwords, and sessions are encrypted in transit using '
          'TLS. Location history is retained only for as long as it is needed '
          'to operate and audit the trip.',
    ),
    LegalSection(
      title: 'Your rights',
      body:
          'You can request a copy of your data, correct your details from the '
          'profile screen at any time, or ask us to delete your account. '
          'Contact support and we will action it.',
    ),
  ];
}
