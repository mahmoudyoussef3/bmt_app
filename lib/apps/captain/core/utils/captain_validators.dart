import 'captain_digits.dart';

/// The rules the captain's auth forms hold their inputs to.
///
/// They live in `core/` because sign-in and the join request validate the same
/// two things and must reject the same values — a phone the login screen would
/// refuse must not be accepted as the phone a request is filed under.
///
/// The phone rule is deliberately the same one the dashboard's fleet forms
/// apply when a driver record is *created* (11 digits, Egyptian mobile prefix):
/// a number the office could not have entered is a number no captain can sign
/// in with, and catching it here costs one field error instead of a round trip
/// that comes back "this number is not registered".
class CaptainValidators {
  const CaptainValidators._();

  static const _mobilePrefixes = {'010', '011', '012', '015'};

  static String? phone(String? value) {
    final digits = CaptainDigits.only(value ?? '');
    if (digits.isEmpty) return 'أدخل رقم الهاتف';
    if (digits.length != 11) return 'رقم الهاتف يتكوّن من ١١ رقمًا';
    if (!_mobilePrefixes.contains(digits.substring(0, 3))) {
      return 'ابدأ الرقم بـ 010 أو 011 أو 012 أو 015';
    }
    return null;
  }

  /// A captain is approved against a name an operator has to recognise on a
  /// contract, so a single word is not enough.
  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'أدخل اسمك بالكامل';
    if (name.length < 6 || name.split(RegExp(r'\s+')).length < 2) {
      return 'أدخل الاسم ثنائيًا على الأقل';
    }
    return null;
  }

  static String? officeCode(String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) return 'أدخل كود المكتب';
    if (code.length < 4) return 'الكود لا يقل عن ٤ خانات';
    return null;
  }
}
