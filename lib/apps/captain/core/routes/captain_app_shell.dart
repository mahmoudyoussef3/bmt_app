import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/assigned_trips/presentation/pages/assigned_trips_page.dart';
import '../../features/communication/presentation/cubit/captain_notification_cubit.dart';
import '../../features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import '../../features/profile/presentation/cubit/driver_profile_cubit.dart';
import '../../features/profile/presentation/pages/driver_profile_page.dart';
import '../../features/trip_history/presentation/cubit/trip_history_cubit.dart';
import '../../features/trip_history/presentation/pages/trip_history_page.dart';
import '../di/captain_di.dart';
import '../widgets/captain_bottom_nav.dart';

class CaptainAppShell extends StatefulWidget {
  const CaptainAppShell({super.key});

  @override
  State<CaptainAppShell> createState() => _CaptainAppShellState();
}

class _CaptainAppShellState extends State<CaptainAppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    CaptainNavTab(
      label: 'اليوم',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    CaptainNavTab(
      label: 'السجل',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
    ),
    CaptainNavTab(
      label: 'حسابي',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssignedTripsCubit>(
          create: (_) => captainGetIt<AssignedTripsCubit>()..load(),
        ),
        BlocProvider<TripHistoryCubit>(
          create: (_) => captainGetIt<TripHistoryCubit>()..load(),
        ),
        BlocProvider<DriverProfileCubit>(
          create: (_) => captainGetIt<DriverProfileCubit>()..load(),
        ),
        BlocProvider<CaptainNotificationCubit>(
          create: (_) =>
              captainGetIt<CaptainNotificationCubit>()..startListening(),
        ),
        BlocProvider<CaptainNotificationBadgeCubit>.value(
          value: captainGetIt<CaptainNotificationBadgeCubit>(),
        ),
      ],
      child: BlocListener<CaptainNotificationCubit, CaptainNotificationState>(
        listener: _showOperationsMessage,
        // extendBody lets pages scroll under the floating nav; pages reserve
        // CaptainBottomNav.reservedSpace so their controls stay reachable.
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              AssignedTripsPage(),
              TripHistoryPage(),
              DriverProfilePage(),
            ],
          ),
          bottomNavigationBar: CaptainBottomNav(
            currentIndex: _currentIndex,
            tabs: _tabs,
            onTabChanged: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }

  void _showOperationsMessage(
    BuildContext context,
    CaptainNotificationState state,
  ) {
    if (state is! CaptainNotificationReceived) return;

    // Not AppSnackbar: this is a longer-lived, dismissible operations
    // broadcast (5s + a close action), not a transient success/warning/error
    // confirmation — a different shape than the ones that helper covers.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('رسالة من العمليات: ${state.message}')),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () =>
              context.read<CaptainNotificationCubit>().clearNotification(),
        ),
      ),
    );
    context.read<CaptainNotificationCubit>().clearNotification();
  }
}
