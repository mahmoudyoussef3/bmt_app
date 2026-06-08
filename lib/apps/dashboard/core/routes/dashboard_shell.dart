import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../features/assignments/presentation/cubit/fleet_assignments_cubit.dart';
import '../../features/assignments/presentation/screens/fleet_assignments_screen.dart';
import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/bookings/presentation/screens/bookings_screen.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import '../../features/dashboard_operations/presentation/cubit/dashboard_workspace_cubit.dart';
import '../../features/drivers/presentation/cubit/drivers_cubit.dart';
import '../../features/drivers/presentation/screens/drivers_screen.dart';
import '../../features/live_trips/presentation/screens/live_trips_screen.dart';
import '../../features/live_trips/presentation/cubit/live_trips_cubit.dart';
import '../../features/payments/presentation/cubit/payments_cubit.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import '../../features/payment_verification/presentation/screens/payment_verification_screen.dart';
import '../../features/permissions/presentation/screens/permissions_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../../features/routes/presentation/screens/routes_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/tickets/presentation/screens/tickets_screen.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/vehicles/presentation/cubit/vehicles_cubit.dart';
import '../../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../di/dashboard_di.dart';
import '../permissions/dashboard_permission.dart';
import '../permissions/dashboard_role.dart';
import '../theme/dashboard_theme_cubit.dart';
import 'dashboard_routes.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  DashboardRole _role = DashboardRole.customerService;
  String _route = DashboardRoutes.home;

  late final List<_DashboardNavItem> _items = [
    const _DashboardNavItem(
      label: 'الرئيسية',
      route: DashboardRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    const _DashboardNavItem(
      label: 'الحجوزات',
      route: DashboardRoutes.bookings,
      icon: Icons.event_seat_outlined,
      selectedIcon: Icons.event_seat_rounded,
      permission: DashboardPermission.bookings,
    ),
    const _DashboardNavItem(
      label: 'الرحلات',
      route: DashboardRoutes.trips,
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
      permission: DashboardPermission.trips,
    ),
    const _DashboardNavItem(
      label: 'الرحلات المباشرة',
      route: DashboardRoutes.liveTrips,
      icon: Icons.near_me_outlined,
      selectedIcon: Icons.near_me_rounded,
      permission: DashboardPermission.liveTrips,
    ),
    const _DashboardNavItem(
      label: 'السائقين',
      route: DashboardRoutes.drivers,
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
      permission: DashboardPermission.drivers,
    ),
    const _DashboardNavItem(
      label: 'التعيينات',
      route: DashboardRoutes.assignments,
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz_rounded,
      permission: DashboardPermission.assignments,
    ),
    const _DashboardNavItem(
      label: 'المركبات',
      route: DashboardRoutes.vehicles,
      icon: Icons.directions_bus_outlined,
      selectedIcon: Icons.directions_bus_rounded,
      permission: DashboardPermission.vehicles,
    ),
    const _DashboardNavItem(
      label: 'المسارات',
      route: DashboardRoutes.routes,
      icon: Icons.alt_route_outlined,
      selectedIcon: Icons.alt_route_rounded,
      permission: DashboardPermission.routes,
    ),
    const _DashboardNavItem(
      label: 'المستخدمين',
      route: DashboardRoutes.users,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      permission: DashboardPermission.users,
    ),
    const _DashboardNavItem(
      label: 'الاشتراكات',
      route: DashboardRoutes.subscriptions,
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      permission: DashboardPermission.subscriptions,
    ),
    const _DashboardNavItem(
      label: 'المدفوعات',
      route: DashboardRoutes.payments,
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
      permission: DashboardPermission.payments,
    ),
    const _DashboardNavItem(
      label: 'تحقق الدفع',
      route: DashboardRoutes.paymentVerification,
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
      permission: DashboardPermission.paymentVerification,
    ),
    const _DashboardNavItem(
      label: 'الشكاوى',
      route: DashboardRoutes.tickets,
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      permission: DashboardPermission.tickets,
    ),
    const _DashboardNavItem(
      label: 'التقارير',
      route: DashboardRoutes.reports,
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      permission: DashboardPermission.reports,
    ),
    const _DashboardNavItem(
      label: 'الإعدادات',
      route: DashboardRoutes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      permission: DashboardPermission.settings,
    ),
    const _DashboardNavItem(
      label: 'الصلاحيات',
      route: DashboardRoutes.permissions,
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings_rounded,
      permission: DashboardPermission.permissions,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    if (!visibleItems.any((item) => item.route == _route)) {
      _route = DashboardRoutes.home;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _DashboardSidebar(
                items: visibleItems,
                role: _role,
                route: _route,
                onRoleChanged: _setRole,
                onRouteChanged: (route) => setState(() => _route = route),
              ),
              Expanded(
                child: Column(
                  children: [
                    _DashboardTopBar(title: _activeTitle, role: _role),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DashboardNavItem> get _visibleItems {
    return _items.where((item) {
      final permission = item.permission;
      if (permission == null) return true;
      return DashboardPermissions.canAccess(_role, permission);
    }).toList();
  }

  String get _activeTitle {
    return _items
        .firstWhere((item) => item.route == _route, orElse: () => _items.first)
        .label;
  }

  void _setRole(DashboardRole role) {
    setState(() {
      _role = role;
      if (!_visibleItems.any((item) => item.route == _route)) {
        _route = DashboardRoutes.home;
      }
    });
  }

  Widget _buildContent() {
    return switch (_route) {
      DashboardRoutes.home => BlocProvider(
        create: (_) => dashboardDi<DashboardHomeCubit>()..load(),
        child: const DashboardHomeScreen(),
      ),
      DashboardRoutes.bookings => BlocProvider(
        create: (_) => dashboardDi<BookingsCubit>()..load(),
        child: const BookingsScreen(),
      ),
      DashboardRoutes.trips => BlocProvider(
        create: (_) => dashboardDi<TripsCubit>()..load(),
        child: const TripsScreen(),
      ),
      DashboardRoutes.liveTrips => BlocProvider(
        create: (_) => dashboardDi<LiveTripsCubit>()..load(),
        child: const LiveTripsScreen(),
      ),
      DashboardRoutes.drivers => BlocProvider(
        create: (_) => dashboardDi<DriversCubit>()..load(),
        child: const DriversScreen(),
      ),
      DashboardRoutes.assignments => BlocProvider(
        create: (_) => dashboardDi<FleetAssignmentsCubit>()..load(),
        child: const FleetAssignmentsScreen(),
      ),
      DashboardRoutes.vehicles => BlocProvider(
        create: (_) => dashboardDi<VehiclesCubit>()..load(),
        child: const VehiclesScreen(),
      ),
      DashboardRoutes.routes => BlocProvider(
        create: (_) => dashboardDi<RoutesCubit>()..load(),
        child: const RoutesScreen(),
      ),
      DashboardRoutes.users => _workspace('users', const UsersScreen()),
      DashboardRoutes.subscriptions => _workspace(
        'subscriptions',
        const SubscriptionsScreen(),
      ),
      DashboardRoutes.payments => BlocProvider(
        create: (_) => dashboardDi<PaymentsCubit>()..load(),
        child: const PaymentsScreen(),
      ),
      DashboardRoutes.paymentVerification => BlocProvider(
        create: (_) => dashboardDi<PaymentVerificationCubit>()..load(),
        child: const PaymentVerificationScreen(),
      ),
      DashboardRoutes.tickets => _workspace('tickets', const TicketsScreen()),
      DashboardRoutes.reports => _workspace('reports', const ReportsScreen()),
      DashboardRoutes.settings => _workspace(
        'settings',
        const SettingsScreen(),
      ),
      DashboardRoutes.permissions => _workspace(
        'permissions',
        const PermissionsScreen(),
      ),
      _ => const DashboardHomeScreen(),
    };
  }

  Widget _workspace(String workspaceId, Widget child) {
    return BlocProvider(
      create: (_) => dashboardDi<DashboardWorkspaceCubit>()..load(workspaceId),
      child: child,
    );
  }
}

class _DashboardNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final DashboardPermission? permission;

  const _DashboardNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    this.permission,
  });
}

class _DashboardSidebar extends StatelessWidget {
  final List<_DashboardNavItem> items;
  final DashboardRole role;
  final String route;
  final ValueChanged<DashboardRole> onRoleChanged;
  final ValueChanged<String> onRouteChanged;

  const _DashboardSidebar({
    required this.items,
    required this.role,
    required this.route,
    required this.onRoleChanged,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        border: Border(left: BorderSide(color: scheme.outline.withAlpha(80))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('لوحة التشغيل', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'نظام عمليات النقل',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.medium),
            _RoleSelector(role: role, onChanged: onRoleChanged),
            const SizedBox(height: AppSpacing.large),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.xSmall),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NavButton(
                    item: item,
                    selected: item.route == route,
                    onTap: () => onRouteChanged(item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final String title;
  final DashboardRole role;

  const _DashboardTopBar({required this.title, required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = context.select(
      (DashboardThemeCubit cubit) => cubit.state.themeMode,
    );
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline.withAlpha(80))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
            onPressed: () {
              context.read<DashboardThemeCubit>().setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: AppSpacing.small),
          StatusChip(label: role.label),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final DashboardRole role;
  final ValueChanged<DashboardRole> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DashboardRole>(
      segments: DashboardRole.values
          .map(
            (role) => ButtonSegment<DashboardRole>(
              value: role,
              label: Text(role.label),
            ),
          )
          .toList(),
      selected: {role},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _DashboardNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withAlpha(180)
          : scheme.surface.withAlpha(0),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
