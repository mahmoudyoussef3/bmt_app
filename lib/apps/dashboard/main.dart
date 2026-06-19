import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'core/theme/dashboard_app_theme.dart';
import 'core/theme/dashboard_theme_cubit.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbwzourpbnmewwklewyr.supabase.co',
    publishableKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
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
        builder: (context, state) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'لوحة خدمة العملاء',
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                theme: DashboardAppTheme.light(),
                darkTheme: DashboardAppTheme.dark(),
                themeMode: state.themeMode,
                home: const DashboardShell(),
              );
            },
          );
        },
      ),
    );
  }
}
