import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'core/theme/dashboard_app_theme.dart';
import 'core/theme/dashboard_theme_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

/// The dashboard is an Arabic-only operational workspace: there is no language
/// switcher, so the locale is pinned rather than read from storage or system.
const String _dashboardLocale = 'ar';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppFlavorConfig.activate(AppFlavor.dashboard);
  final config = AppFlavorConfig.current;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    httpClient: DioHttpClientAdapter(DioFactory.getDio()),
  );

  registerDashboardDependencies();

  runApp(const DashboardWebApp());
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardThemeCubit>(
      create: (_) => dashboardDi<DashboardThemeCubit>()..load(),
      child: BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppFlavorConfig.current.appName,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Pinned, not read from LocaleCubit: the shared flavor bootstrap
            // provides that cubit with an English default, and the dashboard
            // must stay Arabic regardless of it.
            locale: const Locale(_dashboardLocale),
            theme: DashboardAppTheme.light(),
            darkTheme: DashboardAppTheme.dark(),
            themeMode: themeState.themeMode,
            // Also covers overlays that mount above the locale-derived
            // Directionality — dialogs, menus, tooltips, snack bars.
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const DashboardShell(),
          );
        },
      ),
    );
  }
}
