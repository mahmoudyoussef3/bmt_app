import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/core/theme/theme_cubit.dart';
import 'package:bmt_app/features/ops_dashboard/ops_dashboard_module.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => ThemeCubit()..load(),
      child: const DashboardWebApp(),
    ),
  );
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
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
            home: const OpsDashboardModule(),
          ),
        );
      },
    );
  }
}
