import 'package:flutter/material.dart';

import 'package:bmt_app/l10n/app_localizations.dart';

/// Wraps a widget under test in the same localization context the real Client
/// App provides.
///
/// Client widgets read copy through `context.l10n`, which is
/// `AppLocalizations.of(context)!` — a bare `MaterialApp` has no delegates, so
/// that null-check throws and the widget never renders. Tests that skip this
/// therefore fail on a missing harness rather than on the behaviour they mean
/// to assert. The locale is pinned to English so expectations can name literal
/// strings.
Widget clientTestApp(
  Widget home, {
  Locale locale = const Locale('en'),
  NavigatorObserver? navigatorObserver,
  Map<String, WidgetBuilder>? routes,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: [?navigatorObserver],
    routes: routes ?? const <String, WidgetBuilder>{},
    home: home,
  );
}
