import 'package:flutter/widgets.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Ergonomic access to localized strings and layout direction.
///
/// Replaces the verbose `AppLocalizations.of(context)!` with `context.l10n`
/// and gives every widget a cheap `context.isRtl` for direction-aware layout
/// decisions without re-reading [Directionality] by hand.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
