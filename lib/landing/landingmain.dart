import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/l10n/app_localizations.dart';
import 'presentation/landing_page.dart';
import 'presentation/theme/landing_theme.dart';

/// Standalone entry point for the EWT marketing site.
///
/// Deliberately isolated from [main.dart](../main.dart) and the three product
/// flavors it dispatches to (client / captain / dashboard): this page is
/// static marketing content with no signed-in state, so it skips
/// `bootstrapFlavorApp` entirely rather than initializing Supabase, Firebase
/// and `get_it` for a page that talks to none of them.
///
/// It also carries its own theme rather than borrowing [DashboardAppTheme].
/// The `EWT Landing v2` design puts the site on a warm paper ground with its
/// own type ramp — see [LandingPalette] — and the marketing page is the only
/// surface that wears it, so the product themes are left untouched.
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
      locale: const Locale('ar'),
      // The design is a single light composition — the warm paper ground and
      // the navy bands are the contrast, not a second colour scheme — so the
      // page does not follow the platform's dark mode.
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: LandingPalette.page,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LandingPalette.brand,
          brightness: Brightness.light,
          surface: LandingPalette.surface,
        ),
        textTheme: GoogleFonts.cairoTextTheme(),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const LandingPage(),
    );
  }
}
