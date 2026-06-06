import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerCaptainDependencies();
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega Transportation - Driver',
      theme: AppTheme.darkTheme(),
      home: const CaptainAppShell(),
      routes: {
        '/driver/home': (_) => const CaptainAppShell(),
        '/driver/trips': (_) => const CaptainAppShell(),
      },
    );
  }
}
