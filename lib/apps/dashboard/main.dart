import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'core/theme/dashboard_theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbwzourpbnmewwklewyr.supabase.co',
    anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
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
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'لوحة خدمة العملاء',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: state.themeMode,
            home: const DashboardShell(),
          );
        },
      ),
    );
  }
}