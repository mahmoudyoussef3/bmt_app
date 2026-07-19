import 'package:bmt_app/core/validation/contact_validation.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Localized `TextFormField` validators shared across the auth forms.
///
/// Keeps validation rules in one place (reusing [ContactValidation]) instead of
/// re-inlining the same regex and messages on every screen.
class AuthValidators {
  const AuthValidators._();

  static String? email(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.auth_required;
    if (!ContactValidation.isValidEmail(email)) return l10n.auth_invalidEmail;
    return null;
  }

  static String? required(String? value, AppLocalizations l10n) {
    if ((value ?? '').isEmpty) return l10n.auth_required;
    return null;
  }

  static String? fullName(String? value, AppLocalizations l10n) {
    if ((value?.trim() ?? '').length < 2) return l10n.auth_invalidFullName;
    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return l10n.auth_invalidPhone;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if ((value ?? '').length < 6) return l10n.auth_invalidPassword;
    return null;
  }
}
