import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/driver_dashboard_screen.dart';

void main() {
  runApp(const CaptainApp());
}

class CaptainApp extends StatelessWidget {
  const CaptainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Captain App',
      theme: AppTheme.lightTheme(),
      home: const CaptainDashboardScreen(),
    );
  }
}
