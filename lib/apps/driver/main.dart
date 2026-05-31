import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/core/di/di.dart';
import 'package:bmt_app/features/auth/logic/auth_cubit.dart';
import 'package:bmt_app/features/driver/presentation/screens/driver_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup dependency injection, then initialize existing singleton for compatibility
  setupLocator();
  DriverService(); // initialize singleton
  // Attempt lightweight auto-login (non-blocking)
  if (getIt.isRegistered<AuthCubit>()) {
    getIt<AuthCubit>().tryAutoLogin();
  }
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega Transportation — Driver',
      theme: AppTheme.darkTheme(),
      home: const DriverHomeWrapper(),
      routes: {
        '/driver/home': (_) => const DriverHomeWrapper(),
        '/driver/trips': (_) => const DriverHomeWrapper(initialIndex: 1),
      },
    );
  }
}

class DriverHomeWrapper extends StatefulWidget {
  final int initialIndex;
  const DriverHomeWrapper({super.key, this.initialIndex = 0});

  @override
  State<DriverHomeWrapper> createState() => _DriverHomeWrapperState();
}

class _DriverHomeWrapperState extends State<DriverHomeWrapper> {
  @override
  void initState() {
    super.initState();
    DriverService.cubitInstance.loadTodaysTrips();
    DriverService.cubitInstance.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return const DriverHomeScreen();
  }
}
