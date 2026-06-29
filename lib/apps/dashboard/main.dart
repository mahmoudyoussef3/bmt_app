import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'core/theme/dashboard_app_theme.dart';
import 'core/theme/dashboard_theme_cubit.dart';
import 'modules/settings/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'modules/settings/auth/presentation/screens/dashboard_login_screen.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardThemeCubit>(
          create: (_) => dashboardDi<DashboardThemeCubit>()..load(),
        ),
        BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()..load()),
      ],
      child: BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: AppFlavorConfig.current.appName,
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                theme: DashboardAppTheme.light(),
                darkTheme: DashboardAppTheme.dark(),
                themeMode: themeState.themeMode,
                home: const _DashboardAuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shows DashboardLoginScreen when no session, DashboardShell when signed in.
class _DashboardAuthGate extends StatelessWidget {
  const _DashboardAuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) return const DashboardShell();

        return BlocProvider(
          create: (_) => dashboardDi<DashboardAuthCubit>(),
          child: const DashboardLoginScreen(),
        );
      },
    );
  }
}
