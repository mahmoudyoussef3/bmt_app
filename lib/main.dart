import 'package:bmt_app/apps/dashboard/main.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/client/client_app.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://nbwzourpbnmewwklewyr.supabase.co',
      anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
      httpClient: DioHttpClientAdapter(DioFactory.getDio()),
    );
  } catch (_) {
    // Avoid crashing in environments where Supabase is already initialized or connection is mock
  }

  registerCaptainDependencies();
  registerDashboardDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppModeCubit()..load()),
        BlocProvider(create: (_) => LocaleCubit()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppModeCubit, AppModeState>(
      listener: (context, state) {
        _navKey.currentState?.pushNamedAndRemoveUntil(
          state.mode.routePath,
          (_) => false,
        );
      },
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: _navKey,
            title: 'BMT App',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            theme: ThemeData(primarySwatch: Colors.blue),
            routes: {
              '/': (_) => const ClientApp(),
              '/driver': (_) => const CaptainAppShell(),
              '/admin': (_) => const DashboardWebApp(),
              '/ops-dashboard': (_) => const DashboardWebApp(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
