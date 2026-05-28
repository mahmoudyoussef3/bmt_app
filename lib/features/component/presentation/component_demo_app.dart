import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/demo_shell_screen.dart';

class ComponentDemoApp extends StatelessWidget {
  const ComponentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mega Transportation',
      theme: AppTheme.lightTheme(),
      home: const DemoShellScreen(),
      routes: {
        '/daily-booking': (_) => const DailyBookingFlowScreen(),
        '/seat-selection': (_) => const SeatSelectionScreen(),
        '/subscription': (_) => const SubscriptionScreen(),
        '/tracking': (_) => const TrackingScreen(),
      },
    );
  }
}
