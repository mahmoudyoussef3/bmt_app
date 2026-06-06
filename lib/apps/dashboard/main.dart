import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'core/theme/dashboard_theme_cubit.dart';

void main() {
  registerDashboardDependencies();

  runApp(
    BlocProvider(
      create: (_) => dashboardDi<DashboardThemeCubit>()..load(),
      child: const DashboardWebApp(),
    ),
  );
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
      builder: (context, state) {
        return AnimatedTheme(
          data: state.themeMode == ThemeMode.dark
              ? AppTheme.darkTheme()
              : AppTheme.lightTheme(),
          duration: const Duration(milliseconds: 180),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'لوحة خدمة العملاء',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: state.themeMode,
            home: const DashboardShell(),
          ),
        );
      },
    );
  }
}
