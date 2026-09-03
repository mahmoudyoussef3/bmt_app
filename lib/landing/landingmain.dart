import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/l10n/app_localizations.dart';
import 'presentation/landing_page.dart';
import 'presentation/theme/landing_theme.dart';


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
