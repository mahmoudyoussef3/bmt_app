import 'package:flutter/widgets.dart';
import 'package:bmt_app/core/network/api_result.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

extension FailureL10nExt on Failure {
  /// Returns a localized message based on the Failure code.
  /// If the code is unknown, it falls back to a generic error message,
  /// or optionally the original English backend message if preferred.
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (code) {
      case 'TIMEOUT':
        return l10n.error_timeout;
      case 'CANCELLED':
        return l10n.error_cancelled;
      case 'NO_INTERNET':
        return l10n.error_noInternet;
      case '400':
        return l10n.error_badRequest;
      case '401':
        return l10n.error_unauthorized;
      case '403':
        return l10n.error_forbidden;
      case '404':
        return l10n.error_notFound;
      case '422':
        return l10n.error_validation;
      case 'SERVER_ERROR':
        return l10n.error_server;
      case 'UNKNOWN':
      default:
        // You can return the original message if it's a dynamic backend error
        // But for fully localized apps, it's safer to show the generic localized error
        return l10n.error_unknown;
    }
  }
}
