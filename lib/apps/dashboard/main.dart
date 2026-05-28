import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/admin_dashboard_screen.dart';

void main() {
  runApp(const DashboardWebApp());
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Operations Dashboard',
      theme: AppTheme.lightTheme(),
      home: const DashboardWebScreen(),
    );
  }
}
