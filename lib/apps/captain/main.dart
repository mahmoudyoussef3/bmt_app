import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

import 'package:bmt_app/core/flavors/app_bootstrap.dart';

Future<void> main() async {
  await bootstrapFlavorApp(AppFlavor.captain);
}

class CaptainApp extends StatelessWidget {
  const CaptainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppFlavorConfig.current.appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          home: const CaptainAppShell(),
          routes: {
            '/captain/home': (_) => const CaptainAppShell(),
            '/captain/trips': (_) => const CaptainAppShell(),
          },
        );
      },
    );
  }
}
