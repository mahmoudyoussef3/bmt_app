import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/assigned_trips/presentation/pages/assigned_trips_page.dart';
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
  static const _todayTab = 0;

  int _currentIndex = _todayTab;

  void _openTab(int index) => setState(() => _currentIndex = index);

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
        BlocProvider<CaptainNotificationBadgeCubit>.value(
          value: captainGetIt<CaptainNotificationBadgeCubit>(),
        ),
      ],
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const AssignedTripsPage(),
            const TripHistoryPage(),
            const DriverProfilePage(),
          ],
        ),
        bottomNavigationBar: CaptainBottomNav(
          currentIndex: _currentIndex,
          tabs: _tabs,
          onTabChanged: _openTab,
        ),
      ),
    );
  }
}
