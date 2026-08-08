import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'presentation/landing_page.dart';

/// Standalone entry point for the EWT marketing site.
///
/// Deliberately isolated from [main.dart](../main.dart) and the three product
/// flavors it dispatches to (client / captain / dashboard): this page is
/// static marketing content with no signed-in state, so it skips
/// `bootstrapFlavorApp` entirely rather than initializing Supabase, Firebase
/// and `get_it` for a page that talks to none of them. Its only borrowing
/// from the real product is visual — [DashboardAppTheme] and the icon
/// vocabulary the section widgets read, so the pitch looks like the product
/// it is pitching.
///
/// Run with:
/// ```
/// flutter run -t lib/landing/landingmain.dart
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LandingApp());
}

class LandingApp extends StatelessWidget {
  const LandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EWT — Easy Way Transportation',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The dashboard this page markets is Arabic-only and RTL; the landing
      // page pitching it stays in the same language rather than picking up
      // the client app's language switcher.
      locale: const Locale('ar'),
      theme: DashboardAppTheme.light(),
      darkTheme: DashboardAppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const LandingPage(),
    );
  }
}
