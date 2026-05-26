import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/client/presentation/cubits/booking_cubit.dart';
import 'package:bmt_app/features/client/presentation/cubits/bookings_list_cubit.dart';
import 'package:bmt_app/features/client/presentation/cubits/tracking_cubit.dart';
import 'package:bmt_app/features/client/presentation/cubits/subscription_cubit.dart';
import 'package:bmt_app/features/client/presentation/screens/home_screen.dart';
import 'package:bmt_app/features/client/presentation/screens/daily_booking_screen.dart';
import 'package:bmt_app/features/client/presentation/screens/track_vehicle_screen.dart';
import 'package:bmt_app/features/client/presentation/screens/monthly_subscription_screen.dart';
import 'package:bmt_app/features/driver/presentation/cubits/driver_trip_cubit.dart';
import 'package:bmt_app/features/driver/presentation/screens/driver_trip_list_screen.dart';
import 'package:bmt_app/features/admin/presentation/cubits/admin_dashboard_cubit.dart';
import 'package:bmt_app/features/admin/presentation/screens/admin_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega Transportation',
      theme: AppTheme.lightTheme(),
      home: const RoleSelectorScreen(),
      routes: {
        '/role-selector': (_) => const RoleSelectorScreen(),
        '/client-home': (_) => _buildClientHome(),
        '/daily-booking': (_) => _buildDailyBooking(),
        '/track-vehicle': (_) => _buildTrackVehicle(),
        '/monthly-subscription': (_) => _buildMonthlySubscription(),
        '/driver': (_) => _buildDriver(),
        '/admin': (_) => _buildAdmin(),
      },
    );
  }

  Widget _buildClientHome() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BookingsListCubit()),
        BlocProvider(create: (_) => TrackingCubit()),
      ],
      child: const ClientHomeScreen(),
    );
  }

  Widget _buildDailyBooking() {
    return BlocProvider(
      create: (_) => BookingCubit(),
      child: const DailyBookingFlow(),
    );
  }

  Widget _buildTrackVehicle() {
    return BlocProvider(
      create: (_) => TrackingCubit(),
      child: const TrackVehicleScreen(),
    );
  }

  Widget _buildMonthlySubscription() {
    return BlocProvider(
      create: (_) => SubscriptionCubit(),
      child: const MonthlySubscriptionScreen(),
    );
  }

  Widget _buildDriver() {
    return BlocProvider(
      create: (_) => DriverTripCubit(),
      child: const DriverTripListScreen(),
    );
  }

  Widget _buildAdmin() {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(),
      child: const AdminDashboardScreen(),
    );
  }
}

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Title
              Text(
                '🚌',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                'Mega Transportation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Employee Commute Management System',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Role Selection
              Text(
                'Select Your Role',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              // Client Button
              _RoleButton(
                icon: '👤',
                title: 'Client',
                subtitle: 'Book daily trips or\nmanage subscription',
                onPressed: () {
                  Navigator.of(context).pushNamed('/client-home');
                },
              ),
              const SizedBox(height: 16),

              // Driver Button
              _RoleButton(
                icon: '🚗',
                title: 'Driver',
                subtitle: 'Manage your trips\nand passengers',
                onPressed: () {
                  Navigator.of(context).pushNamed('/driver');
                },
              ),
              const SizedBox(height: 16),

              // Admin Button
              _RoleButton(
                icon: '📊',
                title: 'Admin',
                subtitle: 'View dashboard\nand analytics',
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
