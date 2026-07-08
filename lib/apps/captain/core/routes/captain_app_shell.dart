import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_typography.dart';
import '../theme/captain_design_tokens.dart';
import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/assigned_trips/presentation/pages/assigned_trips_page.dart';
import '../../features/communication/presentation/cubit/captain_notification_cubit.dart';
import '../../features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import '../../features/profile/presentation/cubit/driver_profile_cubit.dart';
import '../../features/profile/presentation/pages/driver_profile_page.dart';
import '../../features/trip_history/presentation/cubit/trip_history_cubit.dart';
import '../../features/trip_history/presentation/pages/trip_history_page.dart';
import '../di/captain_di.dart';

class CaptainAppShell extends StatefulWidget {
  const CaptainAppShell({super.key});

  @override
  State<CaptainAppShell> createState() => _CaptainAppShellState();
}

class _CaptainAppShellState extends State<CaptainAppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef(
      label: 'اليوم',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
    ),
    _TabDef(
      label: 'السجل',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
    ),
    _TabDef(
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
          create: (_) => captainGetIt<AssignedTripsCubit>(),
        ),
        BlocProvider<TripHistoryCubit>(
          create: (_) => captainGetIt<TripHistoryCubit>(),
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
        listener: (context, state) {
          if (state is CaptainNotificationReceived) {
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
                    Expanded(
                      child: Text('رسالة من العمليات: ${state.message}'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'إغلاق',
                  textColor: Colors.white,
                  onPressed: () => context
                      .read<CaptainNotificationCubit>()
                      .clearNotification(),
                ),
              ),
            );
            context.read<CaptainNotificationCubit>().clearNotification();
          }
        },
        child: _ShellScaffold(
          currentIndex: _currentIndex,
          tabs: _tabs,
          onTabChanged: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  final int currentIndex;
  final List<_TabDef> tabs;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating nav over content
      body: IndexedStack(
        index: currentIndex,
        children: const [
          AssignedTripsPage(),
          TripHistoryPage(),
          DriverProfilePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s16,
            0,
            CaptainDesignTokens.s16,
            CaptainDesignTokens.s16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: CaptainColors.surfaceFor(context),
              borderRadius: CaptainDesignTokens.br32,
              boxShadow: CaptainDesignTokens.floatingShadow(context),
            ),
            child: ClipRRect(
              borderRadius: CaptainDesignTokens.br32,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s8,
                    vertical: CaptainDesignTokens.s12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(tabs.length, (i) {
                      final tab = tabs[i];
                      final isActive = i == currentIndex;
                      return _NavItem(
                        label: tab.label,
                        icon: isActive ? tab.activeIcon : tab.icon,
                        isActive: isActive,
                        onTap: () => onTabChanged(i),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? CaptainColors.primary
        : CaptainColors.textSecondaryFor(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s20,
          vertical: CaptainDesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? CaptainColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: CaptainDesignTokens.br24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: CaptainDesignTokens.s4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
