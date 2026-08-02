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
import '../../features/live_ops/presentation/cubit/live_ops_cubit.dart';
import '../../features/live_ops/presentation/screens/live_ops_screen.dart';
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
import '../../features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import '../di/dashboard_di.dart';
import '../permissions/dashboard_permission.dart';
import '../permissions/dashboard_role.dart';
import '../session/office_context.dart';
import '../theme/dashboard_colors.dart';
import '../theme/dashboard_icons.dart';
import '../theme/dashboard_theme_cubit.dart';
import 'dashboard_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

// Sidebar section labels (dashboard is Arabic-only, consistent with the
// literal-Arabic convention already used on the home screen).
//
// The groups follow the operator's day, not the database: what is moving now
// (التشغيل), what customers bought (المبيعات), what runs the trips (الأسطول),
// the money (المالية), the people complaining (الدعم), then the console itself
// (النظام). Note that no group shares a name with an item inside it — "المالية"
// used to be both a section and the payments screen within it, so the sidebar
// appeared to contain itself. That is also why the bookings section is called
// "المبيعات" and not "الحجوزات": the latter is the screen inside it.
const String _navOperations = 'التشغيل';
const String _navSales = 'المبيعات';
const String _navFleet = 'الأسطول';
const String _navFinance = 'المالية';
const String _navSupport = 'الدعم';
const String _navSystem = 'النظام';

/// Order groups appear in the sidebar.
const List<String> _navGroupOrder = [
  _navOperations,
  _navSales,
  _navFleet,
  _navFinance,
  _navSupport,
  _navSystem,
];

/// The open module's name, and the section it belongs to, in the top bar.
///
/// Keyed because both strings also appear in the sidebar (and often inside the
/// module itself), so a plain text finder cannot tell the console's "you are
/// here" apart from the nav item it came from.
const Key topBarTitleKey = Key('dashboard-topbar-title');
const Key topBarSubtitleKey = Key('dashboard-topbar-subtitle');

/// Sidebar width when it shows labels, and when it is collapsed to icons.
const double _sidebarWidth = 268;
const double _sidebarRailWidth = 76;

/// Below this the shell swaps the sidebar for a drawer; between it and
/// [_railBreakpoint] the sidebar defaults to the icon rail, because a 268px
/// sidebar on a 1000px laptop eats a quarter of the working area.
const double _drawerBreakpoint = 920;
const double _railBreakpoint = 1180;

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

  /// Operator's explicit choice to collapse the sidebar to icons. `null` means
  /// "follow the window" — wide screens show labels, laptops show the rail —
  /// so the shell adapts until the operator overrides it, and then it obeys.
  bool? _navCollapsed;

  /// One-shot: the home screen's primary action asks for the trip planner, not
  /// just the trips list. Consumed by [TripsScreen], which opens the wizard on
  /// its first frame and then ignores the flag for the rest of its life.
  bool _openTripPlanner = false;

  late final List<_DashboardNavItem> _items = [
    _DashboardNavItem(
      label: 'الرئيسية',
      route: DashboardRoutes.home,
      icon: DashboardIcons.home,
      selectedIcon: DashboardIcons.homeActive,
    ),
    _DashboardNavItem(
      label: 'العمليات المباشرة',
      route: DashboardRoutes.liveOps,
      icon: DashboardIcons.liveOps,
      selectedIcon: DashboardIcons.liveOpsActive,
      permission: DashboardPermission.liveOps,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'الرحلات',
      route: DashboardRoutes.trips,
      icon: DashboardIcons.trips,
      selectedIcon: DashboardIcons.tripsActive,
      permission: DashboardPermission.trips,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'المسارات',
      route: DashboardRoutes.routes,
      icon: DashboardIcons.routes,
      selectedIcon: DashboardIcons.routesActive,
      permission: DashboardPermission.routes,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'الحجوزات',
      route: DashboardRoutes.bookings,
      icon: DashboardIcons.bookings,
      selectedIcon: DashboardIcons.bookingsActive,
      permission: DashboardPermission.bookings,
      group: _navSales,
    ),
    _DashboardNavItem(
      label: 'الاشتراكات',
      route: DashboardRoutes.subscriptions,
      icon: DashboardIcons.subscriptions,
      selectedIcon: DashboardIcons.subscriptionsActive,
      permission: DashboardPermission.subscriptions,
      group: _navSales,
    ),
    _DashboardNavItem(
      // Not "الأسطول": that is this item's *section*, and a section that
      // contains an item of the same name reads as a broken menu.
      label: 'إدارة الأسطول',
      route: DashboardRoutes.fleet,
      icon: DashboardIcons.fleet,
      selectedIcon: DashboardIcons.fleetActive,
      permission: DashboardPermission.fleet,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'طلبات الكباتن',
      route: DashboardRoutes.captainRequests,
      icon: DashboardIcons.captainRequests,
      selectedIcon: DashboardIcons.captainRequestsActive,
      permission: DashboardPermission.captainRequests,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'المدفوعات',
      route: DashboardRoutes.payments,
      icon: DashboardIcons.payments,
      selectedIcon: DashboardIcons.paymentsActive,
      permission: DashboardPermission.payments,
      group: _navFinance,
    ),
  /*  _DashboardNavItem(
      label: 'التقارير',
      route: DashboardRoutes.reports,
      icon: DashboardIcons.reports,
      selectedIcon: DashboardIcons.reportsActive,
      permission: DashboardPermission.reports,
      group: _navFinance,
    ),
    */
    _DashboardNavItem(
      label: 'نظرة المالك',
      route: DashboardRoutes.ownerOverview,
      icon: DashboardIcons.ownerOverview,
      selectedIcon: DashboardIcons.ownerOverviewActive,
      permission: DashboardPermission.ownerOverview,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'برنامج الإحالات',
      route: DashboardRoutes.referrals,
      icon: DashboardIcons.referrals,
      selectedIcon: DashboardIcons.referralsActive,
      permission: DashboardPermission.referrals,
      group: _navFinance,
    ),
    _DashboardNavItem(
      label: 'الشكاوى',
      route: DashboardRoutes.tickets,
      icon: DashboardIcons.tickets,
      selectedIcon: DashboardIcons.ticketsActive,
      permission: DashboardPermission.tickets,
      group: _navSupport,
    ),
    _DashboardNavItem(
      label: 'التقييمات',
      route: DashboardRoutes.reviews,
      icon: DashboardIcons.reviews,
      selectedIcon: DashboardIcons.reviewsActive,
      permission: DashboardPermission.reviews,
      group: _navSupport,
    ),
    _DashboardNavItem(
      label: 'الإشعارات',
      route: DashboardRoutes.notifications,
      icon: DashboardIcons.notifications,
      selectedIcon: DashboardIcons.notificationsActive,
      permission: DashboardPermission.notifications,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'ملف المكتب',
      route: DashboardRoutes.officeProfile,
      icon: DashboardIcons.officeProfile,
      selectedIcon: DashboardIcons.officeProfileActive,
      permission: DashboardPermission.officeProfile,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'مكاتب المنصة',
      route: DashboardRoutes.platformOffices,
      icon: DashboardIcons.platformOffices,
      selectedIcon: DashboardIcons.platformOfficesActive,
      permission: DashboardPermission.platformOffices,
      // The only item in the shell that is not about the signed-in office, so
      // the office role alone cannot authorise it — see [_DashboardNavItem.platformOnly].
      platformOnly: true,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'المستخدمون والصلاحيات',
      route: DashboardRoutes.permissions,
      icon: DashboardIcons.users,
      selectedIcon: DashboardIcons.usersActive,
      permission: DashboardPermission.permissions,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'الإعدادات',
      route: DashboardRoutes.settings,
      icon: DashboardIcons.settings,
      selectedIcon: DashboardIcons.settingsActive,
      permission: DashboardPermission.settings,
      group: _navSystem,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < _drawerBreakpoint;
        // The rail is the default on laptops; the operator's own choice, once
        // made, wins at every width above the drawer breakpoint.
        final collapsed =
            _navCollapsed ?? (constraints.maxWidth < _railBreakpoint);

        if (useDrawer) {
          return Scaffold(
            drawer: Drawer(
              child: SafeArea(
                // A drawer is already an overlay the operator opened on
                // purpose — collapsing it to icons there would hide labels for
                // no gain in space.
                child: _DashboardSidebar(
                  items: visibleItems,
                  office: widget.office,
                  role: _role,
                  route: _route,
                  collapsed: false,
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
                      subtitle: _activeGroup,
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
                  collapsed: collapsed,
                  onRoleChanged: _setRole,
                  onRouteChanged: _openRoute,
                  onToggleCollapsed: () =>
                      setState(() => _navCollapsed = !collapsed),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DashboardTopBar(
                        title: _activeTitle,
                        subtitle: _activeGroup,
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

  _DashboardNavItem get _activeItem => _items.firstWhere(
    (item) => item.route == _route,
    orElse: () => _items.first,
  );

  String get _activeTitle => _activeItem.label;

  /// The section the open module belongs to — one line of "you are here" above
  /// the page title, so the top bar says where in the console the operator is
  /// rather than only what the screen is called.
  String? get _activeGroup => _activeItem.group;

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

    setState(() {
      _route = route;
      if (route != DashboardRoutes.trips) _openTripPlanner = false;
    });
    return true;
  }

  /// "Create a trip" from anywhere: open Trips *and* the planner on top of it,
  /// so the primary action on the home screen is one click, not two screens.
  void _startTripPlanner() {
    if (!_canOpenRoute(DashboardRoutes.trips)) {
      _openRoute(DashboardRoutes.trips);
      return;
    }
    setState(() {
      _route = DashboardRoutes.trips;
      _openTripPlanner = true;
    });
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
          BlocProvider(
            create: (_) => dashboardDi<DashboardHomeCubit>()..load(),
          ),
          BlocProvider(
            create: (_) =>
                dashboardDi<OperationalAlertsCubit>()..startWatching(),
          ),
        ],
        child: DashboardHomeScreen(
          office: widget.office,
          onOpenModule: _openRoute,
          onCreateTrip: _startTripPlanner,
        ),
      ),
      DashboardRoutes.liveOps => BlocProvider(
        create: (_) => dashboardDi<LiveOpsCubit>()..startWatching(),
        child: LiveOpsScreen(
          // The signed-in role, not the locally switched `_role`: closing a
          // report writes a permanent audit trail, so the capability must follow
          // the real account and not a debug role selector.
          canResolveIncidents: DashboardPermissions.canAccess(
            widget.office.role,
            DashboardPermission.liveOpsIncidentAction,
          ),
        ),
      ),
      DashboardRoutes.bookings => BlocProvider(
        create: (_) => dashboardDi<BookingsCubit>()..load(),
        child: const BookingsScreen(),
      ),
      DashboardRoutes.trips => TripsScreen(
        onOpenModule: _openRoute,
        openPlannerOnStart: _openTripPlanner,
      ),
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
          BlocProvider(
            create: (_) => dashboardDi<DashboardHomeCubit>()..load(),
          ),
          BlocProvider(
            create: (_) =>
                dashboardDi<OperationalAlertsCubit>()..startWatching(),
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
  final bool collapsed;
  final ValueChanged<DashboardRole> onRoleChanged;
  final ValueChanged<String> onRouteChanged;
  final VoidCallback? onToggleCollapsed;

  const _DashboardSidebar({
    required this.items,
    required this.office,
    required this.role,
    required this.route,
    required this.onRouteChanged,
    this.collapsed = false,
    required this.onRoleChanged,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? _sidebarRailWidth : _sidebarWidth;

    return AnimatedContainer(
      duration: AppTokens.motionBase,
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: DashboardColors.sidebar(context),
        border: BorderDirectional(
          end: BorderSide(color: DashboardColors.border(context)),
        ),
      ),
      // The contents lay out at the *target* width for the whole animation and
      // are clipped to the width the frame is currently at. Letting them size
      // to the animating box instead makes every nav label overflow its row for
      // the ~180ms the sidebar is between the two widths.
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minWidth: width,
          maxWidth: width,
          child: _content(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? AppSpacing.small : AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OfficeIdentityHeader(
            office: office,
            collapsed: collapsed,
            onToggleCollapsed: onToggleCollapsed,
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(child: _buildNavList(context)),
          const SizedBox(height: AppSpacing.small),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.small),
          // Role switching is a debug affordance, not part of the product —
          // it now sits with the account block at the bottom instead of
          // above the navigation, where it read as a real setting.
          if (kDebugMode && !collapsed) ...[
            _RoleSelector(role: role, onChanged: onRoleChanged),
            const SizedBox(height: AppSpacing.small),
          ],
          _AccountFooter(office: office, role: role, collapsed: collapsed),
        ],
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
        ..add(_NavSectionHeader(label: group, collapsed: collapsed))
        ..addAll(groupItems.map(_navButton));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: children.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.xSmall),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _navButton(_DashboardNavItem item) => _NavButton(
    item: item,
    selected: item.route == route,
    collapsed: collapsed,
    onTap: () => onRouteChanged(item.route),
  );
}

/// The label above each nav group. Collapsed, the label has nowhere to go, so
/// the group boundary is drawn as a short rule instead of being dropped —
/// otherwise the rail becomes nineteen undifferentiated icons.
class _NavSectionHeader extends StatelessWidget {
  final String label;
  final bool collapsed;

  const _NavSectionHeader({required this.label, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Divider(height: 1, color: DashboardColors.divider(context)),
      );
    }

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
          color: DashboardColors.sidebarSectionInk(context),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Who is signed in, and the way out.
///
/// Signing out used to live only inside Settings — three clicks and a scroll
/// from anywhere else in the console, on a screen an operator has no other
/// reason to open. It belongs next to the identity it ends.
class _AccountFooter extends StatelessWidget {
  const _AccountFooter({
    required this.office,
    required this.role,
    required this.collapsed,
  });

  final OfficeContext office;
  final DashboardRole role;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = office.displayName.characters.isEmpty
        ? '؟'
        : office.displayName.characters.first;

    final avatar = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final signOut = IconButton(
      tooltip: 'تسجيل الخروج',
      onPressed: () => _confirmSignOut(context),
      icon: const Icon(DashboardIcons.logout),
      style: IconButton.styleFrom(foregroundColor: scheme.error),
    );

    if (collapsed) {
      return Column(
        children: [
          Tooltip(
            message: '${office.displayName} · ${role.label}',
            child: avatar,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          signOut,
        ],
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                office.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                role.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        signOut,
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد إنهاء جلستك الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await dashboardDi<DashboardAuthCubit>().signOut();
    }
  }
}

/// Which office this workspace belongs to, and who is signed in.
///
/// Replaces the generic "لوحة التحكم / النظام" title the sidebar carried while
/// there was only ever one office. With a marketplace, an operator has to be
/// able to tell at a glance whose data is on screen — every list below is
/// filtered to this office and nothing else on the page says which one it is.
class _OfficeIdentityHeader extends StatelessWidget {
  const _OfficeIdentityHeader({
    required this.office,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final OfficeContext office;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = office.officeName.trim().isEmpty
        ? AppLocalizations.of(context)!.dashboard_panel
        : office.officeName.trim();

    final toggle = onToggleCollapsed == null
        ? null
        : IconButton(
            tooltip: collapsed ? 'توسيع القائمة' : 'طيّ القائمة',
            onPressed: onToggleCollapsed,
            icon: Icon(
              collapsed ? DashboardIcons.expandNav : DashboardIcons.collapseNav,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          );

    if (collapsed) {
      return Column(
        children: [
          Tooltip(
            message: name,
            child: _OfficeAvatar(logoUrl: office.logoUrl, name: name),
          ),
          if (toggle != null) ...[const SizedBox(height: 4), toggle],
        ],
      );
    }

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
                office.isListed ? 'معروض في السوق' : 'غير معروض في السوق',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ?toggle,
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

  /// The nav section the open module sits in, e.g. "التشغيل". Absent for the
  /// home screen, which belongs to no section.
  final String? subtitle;
  final DashboardRole role;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;

  const _DashboardTopBar({
    required this.title,
    required this.role,
    this.subtitle,
    this.onOpenMenu,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select(
      (DashboardThemeCubit cubit) => cubit.state.themeMode,
    );
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      decoration: BoxDecoration(
        color: DashboardColors.topBar(context),
        border: Border(
          bottom: BorderSide(color: DashboardColors.border(context)),
        ),
      ),
      child: Row(
        children: [
          if (onOpenMenu != null) ...[
            IconButton(
              tooltip: AppLocalizations.of(context)!.dashboard_menu,
              onPressed: onOpenMenu,
              icon: const Icon(DashboardIcons.menu),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    key: topBarSubtitleKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                Text(
                  title,
                  key: topBarTitleKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
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
              child: const Icon(DashboardIcons.notifications),
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
  final bool collapsed;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected
        ? DashboardColors.sidebarSelectedInk(context)
        : DashboardColors.sidebarInk(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    final icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 20,
      color: ink,
    );

    final button = Material(
      color: selected
          ? DashboardColors.sidebarSelected(context)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        // A visible hover wash: without it the only way to tell a nav row is
        // clickable is to click it.
        hoverColor: DashboardColors.tableRowHover(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? AppSpacing.small : AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: collapsed
              ? SizedBox(height: 24, child: Center(child: icon))
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    // Collapsed, the label *is* the tooltip — an icon rail with no tooltips is
    // a guessing game, which is exactly what this redesign set out to remove.
    if (!collapsed) return button;
    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: button,
    );
  }
}
