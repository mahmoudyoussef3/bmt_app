/// Shared rules for the two contact fields every app collects: email and an
/// Egyptian mobile number.
///
/// Sign-up and the profile editor both write to `clients.phone`, so they must
/// agree on what a stored number looks like — otherwise the same rider is one
/// person at sign-up and another after an edit.
abstract final class ContactValidation {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Egyptian mobiles are `+20` followed by `1`, a carrier digit (0/1/2/5) and
  /// eight subscriber digits.
  static final RegExp _egyptianMobile = RegExp(r'^\+201[0125]\d{8}$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  /// Canonical E.164 form. Accepts what riders actually type — `01012345678`,
  /// `20 10 1234 5678`, `+20 10 1234 5678`, spaces and dashes included.
  static String normalizeEgyptianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (digits.isEmpty) return '';
    if (digits.startsWith('+20')) return digits;
    if (digits.startsWith('20')) return '+$digits';
    if (digits.startsWith('0')) return '+20${digits.substring(1)}';
    return '+20$digits';
  }

  static bool isValidEgyptianPhone(String value) =>
      _egyptianMobile.hasMatch(normalizeEgyptianPhone(value));
}
