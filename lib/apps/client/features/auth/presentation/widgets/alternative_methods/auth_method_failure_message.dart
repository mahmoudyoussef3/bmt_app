import 'package:bmt_app/l10n/app_localizations.dart';

import '../../../domain/entities/auth_method_failure.dart';

/// Turns a typed [AuthMethodFailure] into the sentence a rider reads.
///
/// The mapping lives in presentation, not in the cubit, because it needs an
/// [AppLocalizations] and therefore a `BuildContext` — the same reason
/// `AuthValidators` takes one. Keeping it out of the state is what lets the
/// error survive a language change without being re-emitted.
///
/// Returns `null` for [AuthMethodFailure.cancelled]: the rider closed the
/// provider sheet themselves and already knows why nothing happened. Telling
/// them "sign-in was cancelled" in a red banner would be the app reporting the
/// rider's own decision back at them as a fault.
String? authMethodFailureMessage(
  AuthMethodFailure failure,
  AppLocalizations l10n,
) {
  return switch (failure) {
    AuthMethodFailure.cancelled => null,
    AuthMethodFailure.network => l10n.error_noInternet,
    AuthMethodFailure.invalidPhone => l10n.auth_invalidPhone,
    AuthMethodFailure.invalidCode => l10n.auth_otpInvalidCode,
    AuthMethodFailure.expiredCode => l10n.auth_otpExpiredCode,
    
    AuthMethodFailure.rateLimited => l10n.auth_otpRateLimited,
    AuthMethodFailure.unavailable => l10n.auth_methodUnavailable,
    AuthMethodFailure.unknown => l10n.auth_unknownError,
  };
}
