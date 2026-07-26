import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/bookings/presentation/screens/bookings_screen.dart';
import '../../features/captain_requests/presentation/cubit/captain_requests_cubit.dart';
import '../../features/captain_requests/presentation/screens/captain_requests_screen.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import '../../features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import '../../features/fleet/overview/presentation/screens/fleet_overview_screen.dart';
import '../../features/fleet/shared/domain/entities/fleet_common.dart';
import '../../features/notifications/presentation/cubit/notifications_dispatch_cubit.dart';
import '../../features/notifications/presentation/cubit/operational_alerts_badge_cubit.dart';
import '../../features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import '../../features/notifications/presentation/screens/notifications_center_screen.dart';
import '../../features/finance/presentation/cubit/finance_cubit.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/office_profile/presentation/cubit/office_profile_cubit.dart';
import '../../features/office_profile/presentation/screens/office_profile_screen.dart';
import '../../features/platform_admin/presentation/cubit/platform_admin_cubit.dart';
import '../../features/platform_admin/presentation/screens/platform_offices_screen.dart';
import '../../features/owner_overview/presentation/cubit/owner_overview_cubit.dart';
import '../../features/owner_overview/presentation/screens/owner_overview_screen.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/referrals/presentation/cubit/referral_cubit.dart';
import '../../features/referrals/presentation/screens/referral_management_screen.dart';
import '../../features/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import '../../features/payment_verification/presentation/screens/payment_verification_screen.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reviews/presentation/cubit/reviews_cubit.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../../features/routes/presentation/screens/routes_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tickets/presentation/screens/tickets_screen.dart';
import '../../features/tickets/presentation/cubit/tickets_cubit.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../di/dashboard_di.dart';
import '../permissions/dashboard_permission.dart';
import '../permissions/dashboard_role.dart';
import '../session/office_context.dart';
import '../theme/dashboard_theme_cubit.dart';
import 'dashboard_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

// Sidebar section labels (dashboard is Arabic-only, consistent with the
// literal-Arabic convention already used on the home screen).
const String _navOperations = 'التشغيل';
const String _navFleet = 'الأسطول';
const String _navFinance = 'المالية';
const String _navSupport = 'الدعم';
const String _navSystem = 'النظام';

/// Order groups appear in the sidebar.
const List<String> _navGroupOrder = [
  _navOperations,
  _navFleet,
  _navFinance,
  _navSupport,
  _navSystem,
];

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.office});

  /// The signed-in operator's office. The shell is only ever mounted behind the auth
  /// gate, so this is always present — there is no "no office" fallback to default to.
  final OfficeContext office;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  // Role comes from the authenticated office context. It is no longer defaulted to
  // admin: with multiple offices, guessing full access is exactly the wrong default.
  late DashboardRole _role = widget.office.role;
  String _route = DashboardRoutes.home;

  late final List<_DashboardNavItem> _items = [
    _DashboardNavItem(
      label: 'الرئيسية',
      route: DashboardRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _DashboardNavItem(
      label: 'الحجوزات',
      route: DashboardRoutes.bookings,
      icon: Icons.event_seat_outlined,
      selectedIcon: Icons.event_seat_rounded,
      permission: DashboardPermission.bookings,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'الرحلات',
      route: DashboardRoutes.trips,
      icon: Icons.directions_bus_outlined,
      selectedIcon: Icons.directions_bus_rounded,
      permission: DashboardPermission.trips,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'المسارات',
      route: DashboardRoutes.routes,
      icon: Icons.alt_route_outlined,
      selectedIcon: Icons.alt_route_rounded,
      permission: DashboardPermission.routes,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'إدارة الأسطول',
      route: DashboardRoutes.fleet,
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
      permission: DashboardPermission.fleet,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'طلبات الكباتن',
      route: DashboardRoutes.captainRequests,
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg_rounded,
      permission: DashboardPermission.captainRequests,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'المالية',
      route: DashboardRoutes.payments,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      permission: DashboardPermission.payments,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'الاشتراكات',
      route: DashboardRoutes.subscriptions,
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      permission: DashboardPermission.subscriptions,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'برنامج الإحالات',
      route: DashboardRoutes.referrals,
      icon: Icons.card_giftcard_outlined,
      selectedIcon: Icons.card_giftcard_rounded,
      permission: DashboardPermission.referrals,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'التقارير',
      route: DashboardRoutes.reports,
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      permission: DashboardPermission.reports,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'نظرة المالك',
      route: DashboardRoutes.ownerOverview,
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      permission: DashboardPermission.ownerOverview,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'الشكاوى',
      route: DashboardRoutes.tickets,
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      permission: DashboardPermission.tickets,
      group: _navSupport,
    ),
    _DashboardNavItem(
      label: 'التقييمات',
      route: DashboardRoutes.reviews,
      icon: Icons.star_border_rounded,
      selectedIcon: Icons.star_rate_rounded,
      permission: DashboardPermission.reviews,
      group: _navSupport,
    ),
    _DashboardNavItem(
      label: 'الإشعارات',
      route: DashboardRoutes.notifications,
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      permission: DashboardPermission.notifications,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'ملف المكتب',
      route: DashboardRoutes.officeProfile,
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      permission: DashboardPermission.officeProfile,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'مكاتب المنصة',
      route: DashboardRoutes.platformOffices,
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment_rounded,
      permission: DashboardPermission.platformOffices,
      // The only item in the shell that is not about the signed-in office, so
      // the office role alone cannot authorise it — see [_DashboardNavItem.platformOnly].
      platformOnly: true,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'المستخدمون والصلاحيات',
      route: DashboardRoutes.permissions,
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings_rounded,
      permission: DashboardPermission.permissions,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'الإعدادات',
      route: DashboardRoutes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      permission: DashboardPermission.settings,
      group: _navSystem,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactNavigation = constraints.maxWidth < 920;

        if (useCompactNavigation) {
          return Scaffold(
            drawer: Drawer(
              child: SafeArea(
                child: _DashboardSidebar(
                  items: visibleItems,
                  office: widget.office,
                  role: _role,
                  route: _route,
                  onRoleChanged: _setRole,
                  onRouteChanged: (route) {
                    if (_openRoute(route)) {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ),
            ),
            body: SafeArea(
              child: Builder(
                builder: (context) => Column(
                  children: [
                    _DashboardTopBar(
                      title: _activeTitle,
                      role: _role,
                      onOpenMenu: () => Scaffold.of(context).openDrawer(),
                      onOpenNotifications: () =>
                          _openRoute(DashboardRoutes.notifications),
                    ),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                _DashboardSidebar(
                  items: visibleItems,
                  office: widget.office,
                  role: _role,
                  route: _route,
                  onRoleChanged: _setRole,
                  onRouteChanged: _openRoute,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DashboardTopBar(
                        title: _activeTitle,
                        role: _role,
                        onOpenNotifications: () =>
                            _openRoute(DashboardRoutes.notifications),
                      ),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_DashboardNavItem> get _visibleItems {
    return _items.where(_isItemAllowed).toList();
  }

  bool _isItemAllowed(_DashboardNavItem item) {
    if (item.platformOnly && !widget.office.isPlatformAdmin) return false;
    final permission = item.permission;
    if (permission == null) return true;
    return DashboardPermissions.canAccess(_role, permission);
  }

  String get _activeTitle {
    return _items
        .firstWhere((item) => item.route == _route, orElse: () => _items.first)
        .label;
  }

  void _setRole(DashboardRole role) {
    setState(() {
      _role = role;
      if (!_canOpenRoute(_route)) {
        _route = DashboardRoutes.home;
      }
    });
  }

  bool _openRoute(String route) {
    if (!_canOpenRoute(route)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dashboard_unauthorized),
        ),
      );
      return false;
    }

    setState(() => _route = route);
    return true;
  }

  bool _canOpenRoute(String route) {
    final item = _items.firstWhere(
      (item) => item.route == route,
      orElse: () => _items.first,
    );
    return _isItemAllowed(item);
  }

  Widget _buildContent() {
    return switch (_route) {
      DashboardRoutes.home => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => dashboardDi<DashboardHomeCubit>()..load()),
          BlocProvider(
            create: (_) => dashboardDi<OperationalAlertsCubit>()..startWatching(),
          ),
        ],
        child: DashboardHomeScreen(
          office: widget.office,
          onOpenModule: _openRoute,
        ),
      ),
      DashboardRoutes.bookings => BlocProvider(
        create: (_) => dashboardDi<BookingsCubit>()..load(),
        child: const BookingsScreen(),
      ),
      DashboardRoutes.trips => const TripsScreen(),
      DashboardRoutes.fleet => BlocProvider(
        create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
        child: const FleetOverviewScreen(),
      ),
      DashboardRoutes.captainRequests => BlocProvider(
        create: (_) => dashboardDi<CaptainRequestsCubit>()..load(),
        child: const CaptainRequestsScreen(),
      ),
      DashboardRoutes.drivers => BlocProvider(
        create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
        child: const FleetOverviewScreen(initialTab: FleetTab.drivers),
      ),
      DashboardRoutes.assignments => BlocProvider(
        create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
        child: const FleetOverviewScreen(initialTab: FleetTab.drivers),
      ),
      DashboardRoutes.vehicles => BlocProvider(
        create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
        child: const FleetOverviewScreen(initialTab: FleetTab.vehicles),
      ),
      DashboardRoutes.routes => BlocProvider(
        create: (_) => dashboardDi<RoutesCubit>()..load(),
        child: const RoutesScreen(),
      ),
      DashboardRoutes.users => const UsersScreen(),
      DashboardRoutes.subscriptions => BlocProvider(
        create: (_) => dashboardDi<SubscriptionsCubit>()..load(),
        child: const SubscriptionsScreen(),
      ),
      DashboardRoutes.referrals => BlocProvider(
        create: (_) => dashboardDi<ReferralCubit>()..load(),
        child: const ReferralManagementScreen(),
      ),
      DashboardRoutes.ownerOverview => BlocProvider(
        create: (_) => dashboardDi<OwnerOverviewCubit>()..load(),
        child: const OwnerOverviewScreen(),
      ),
      DashboardRoutes.payments => BlocProvider(
        create: (_) => dashboardDi<FinanceCubit>()..load(),
        child: const FinanceScreen(),
      ),
      DashboardRoutes.paymentVerification => BlocProvider(
        create: (_) => dashboardDi<PaymentVerificationCubit>()..load(),
        child: const PaymentVerificationScreen(),
      ),
      DashboardRoutes.tickets => BlocProvider(
        create: (_) => dashboardDi<TicketsCubit>()..load(),
        child: const TicketsScreen(),
      ),
      DashboardRoutes.reviews => BlocProvider(
        create: (_) => dashboardDi<ReviewsCubit>()..load(),
        child: const ReviewsScreen(),
      ),
      DashboardRoutes.reports => BlocProvider(
        create: (_) => dashboardDi<ReportsCubit>()..load(),
        child: const ReportsScreen(),
      ),
      DashboardRoutes.notifications => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => dashboardDi<OperationalAlertsCubit>()),
          BlocProvider(
            create: (_) => dashboardDi<NotificationsDispatchCubit>(),
          ),
        ],
        child: NotificationsCenterScreen(onOpenRoute: _openRoute),
      ),
      DashboardRoutes.officeProfile => BlocProvider(
        create: (_) => dashboardDi<OfficeProfileCubit>()..load(),
        child: OfficeProfileScreen(
          // The signed-in role, not the locally switched `_role`: only the
          // former is what RLS will actually honour on the update.
          canEdit: widget.office.role == DashboardRole.admin,
        ),
      ),
      DashboardRoutes.platformOffices => BlocProvider(
        create: (_) => dashboardDi<PlatformAdminCubit>()..load(),
        child: const PlatformOfficesScreen(),
      ),
      DashboardRoutes.settings => const SettingsScreen(),
      // Access control *is* user administration: one screen listing every
      // dashboard account with its role, rather than a separate matrix page.
      DashboardRoutes.permissions => const UsersScreen(),
      _ => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => dashboardDi<DashboardHomeCubit>()..load()),
          BlocProvider(
            create: (_) => dashboardDi<OperationalAlertsCubit>()..startWatching(),
          ),
        ],
        child: DashboardHomeScreen(
          office: widget.office,
          onOpenModule: _openRoute,
        ),
      ),
    };
  }
}

class _DashboardNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final DashboardPermission? permission;

  /// Section this item belongs to in the grouped sidebar. `null` = top-level
  /// (rendered above all groups, e.g. the command center home).
  final String? group;

  /// Requires the signed-in operator to be an EWT **platform** admin, on top of
  /// whatever [permission] asks for.
  ///
  /// [permission] is evaluated against `_role`, which is the office role and is
  /// switchable in debug builds by the role selector. That is fine for every
  /// other item — they all act inside the operator's own office, and the server
  /// scopes them to it regardless. Platform administration is the exception: it
  /// reaches across offices, so it is gated on the authenticated identity itself
  /// rather than on a role a debug switch can change.
  final bool platformOnly;

  const _DashboardNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    this.permission,
    this.group,
    this.platformOnly = false,
  });
}

class _DashboardSidebar extends StatelessWidget {
  final List<_DashboardNavItem> items;
  final OfficeContext office;
  final DashboardRole role;
  final String route;
  final ValueChanged<DashboardRole> onRoleChanged;
  final ValueChanged<String> onRouteChanged;

  const _DashboardSidebar({
    required this.items,
    required this.office,
    required this.role,
    required this.route,
    required this.onRoleChanged,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(80),
          border: BorderDirectional(
            end: BorderSide(color: scheme.outline.withAlpha(80)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OfficeIdentityHeader(office: office),
              const SizedBox(height: AppSpacing.medium),
              if (kDebugMode) ...[
                _RoleSelector(role: role, onChanged: onRoleChanged),
                const SizedBox(height: AppSpacing.large),
              ],
              Expanded(child: _buildNavList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavList(BuildContext context) {
    final topLevel = items.where((i) => i.group == null);
    final children = <Widget>[for (final item in topLevel) _navButton(item)];

    for (final group in _navGroupOrder) {
      final groupItems = items.where((i) => i.group == group).toList();
      if (groupItems.isEmpty) continue;
      children
        ..add(_NavSectionHeader(label: group))
        ..addAll(groupItems.map(_navButton));
    }

    return ListView.separated(
      itemCount: children.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.xSmall),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _navButton(_DashboardNavItem item) => _NavButton(
    item: item,
    selected: item.route == route,
    onTap: () => onRouteChanged(item.route),
  );
}

class _NavSectionHeader extends StatelessWidget {
  final String label;

  const _NavSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.xSmall,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Which office this workspace belongs to, and who is signed in.
///
/// Replaces the generic "لوحة التحكم / النظام" title the sidebar carried while
/// there was only ever one office. With a marketplace, an operator has to be
/// able to tell at a glance whose data is on screen — every list below is
/// filtered to this office and nothing else on the page says which one it is.
class _OfficeIdentityHeader extends StatelessWidget {
  const _OfficeIdentityHeader({required this.office});

  final OfficeContext office;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = office.officeName.trim().isEmpty
        ? AppLocalizations.of(context)!.dashboard_panel
        : office.officeName.trim();

    return Row(
      children: [
        _OfficeAvatar(logoUrl: office.logoUrl, name: name),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${office.displayName} · ${office.role.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfficeAvatar extends StatelessWidget {
  const _OfficeAvatar({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = logoUrl?.trim() ?? '';
    final initial = name.characters.isEmpty ? '؟' : name.characters.first;

    final fallback = Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final String title;
  final DashboardRole role;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;

  const _DashboardTopBar({
    required this.title,
    required this.role,
    this.onOpenMenu,
    this.onOpenNotifications,
  });

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
          if (onOpenMenu != null) ...[
            IconButton(
              tooltip: AppLocalizations.of(context)!.dashboard_menu,
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (onOpenNotifications != null) ...[
            _NotificationsBell(onTap: onOpenNotifications!),
            const SizedBox(width: AppSpacing.xSmall),
          ],
          IconButton(
            tooltip: isDark
                ? AppLocalizations.of(context)!.dashboard_lightMode
                : AppLocalizations.of(context)!.dashboard_darkMode,
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

class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The badge cubit is a lazy singleton — provide by value so it is not
    // closed when this transient top bar rebuilds.
    return BlocProvider.value(
      value: dashboardDi<OperationalAlertsBadgeCubit>(),
      child: BlocBuilder<OperationalAlertsBadgeCubit, int>(
        builder: (context, count) {
          return IconButton(
            tooltip: 'الإشعارات',
            onPressed: onTap,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text(count > 99 ? '99+' : '$count'),
              child: const Icon(Icons.notifications_outlined),
            ),
          );
        },
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
              label: Text(
                role.label,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
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
