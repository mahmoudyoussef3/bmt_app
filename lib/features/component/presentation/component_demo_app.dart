import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/admin_dashboard_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/driver_dashboard_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/subscription_confirmation_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/demo_shell_screen.dart';

class ComponentDemoApp extends StatelessWidget {
  const ComponentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mega Transportation',
      // Force dark theme across the client demo app
      theme: AppTheme.darkTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const DemoShellScreen(),
      routes: {
        '/daily-booking': (_) => const DailyBookingFlowScreen(),
        '/seat-selection': (_) => const SeatSelectionScreen(),
        '/payment-demo': (_) => PaymentCheckoutScreen(
          checkoutData: PaymentCheckoutData(
            pickupPoint: 'Banha Station',
            destination: 'Smart Village',
            vehicleNumber: 'MB-15-2847',
            departureTime: '8:40 AM',
            arrivalTime: '9:20 AM',
            selectedSeat: '6',
            driverName: 'Ahmed Mohamed',
          ),
        ),
        '/subscription': (_) => const SubscriptionScreen(),
        '/subscription-confirmation': (_) =>
            const SubscriptionConfirmationScreen(
              pickup: '',
              destination: '',
              time: '',
              planName: 'Monthly',
              price: 'EGP 1,200/month',
            ),
        '/tracking': (_) => const TrackingScreen(),
        '/driver': (_) => const CaptainDashboardScreen(),
        '/admin': (_) => const DashboardWebScreen(),
      },
    );
  }
}
