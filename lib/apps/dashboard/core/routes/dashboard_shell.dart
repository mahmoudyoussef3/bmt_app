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
import '../../features/business_overview/presentation/cubit/business_overview_cubit.dart';
import '../../features/business_overview/presentation/screens/business_overview_screen.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import '../../features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import '../../features/fleet/overview/presentation/screens/fleet_overview_screen.dart';
import '../../features/fleet/shared/domain/entities/fleet_common.dart';
import '../../features/live_ops/presentation/cubit/live_ops_cubit.dart';
import '../../features/live_ops/presentation/screens/live_ops_screen.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
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
import '../../features/office_billing/presentation/cubit/office_billing_cubit.dart';
import '../../features/office_billing/presentation/screens/office_billing_screen.dart';
import '../../features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import '../../features/platform_licensing/presentation/screens/platform_audit_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_billing_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_features_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_licenses_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_plans_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_usage_screen.dart';
import '../di/dashboard_di.dart';
import '../entitlements/entitlement_context.dart';
import '../entitlements/entitlement_service.dart';
import '../entitlements/licensing_dialogs.dart';
import '../entitlements/licensing_failure.dart';
import '../entitlements/licensing_guard.dart';
import '../permissions/dashboard_permission.dart';
import '../permissions/dashboard_role.dart';
import '../session/office_context.dart';
import '../theme/dashboard_colors.dart';
import '../theme/dashboard_icons.dart';
import '../theme/dashboard_theme_cubit.dart';
import 'dashboard_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

const String _navOperations = 'التشغيل';
const String _navSales = 'المبيعات';
const String _navFleet = 'الأسطول';
const String _navFinance = 'المالية';
const String _navSupport = 'الدعم';
const String _navSystem = 'النظام';

/// EWT's own console, not the office's. Visible only to platform admins, and
/// placed after النظام so an office owner's sidebar never changes shape.
const String _navPlatform = 'المنصة';

/// Order groups appear in the sidebar.
const List<String> _navGroupOrder = [
  _navOperations,
  _navSales,
  _navFleet,
  _navFinance,
  _navSupport,
  _navSystem,
  _navPlatform,
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
  const DashboardShell({super.key, required this.office, this.initialRoute});

  /// The signed-in operator's office. The shell is only ever mounted behind the auth
  /// gate, so this is always present — there is no "no office" fallback to default to.
  final OfficeContext office;

  /// Which module the console opens on. Null means [DashboardRoutes.home], which
  /// is what sign-in always wants; it is settable so a harness can mount one
  /// module directly instead of driving the sidebar to reach it.
  final String? initialRoute;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  
  late DashboardRole _role = widget.office.role;
  late String _route = widget.initialRoute ?? DashboardRoutes.home;

  /// Operator's explicit choice to collapse the sidebar to icons. `null` means
  /// "follow the window" — wide screens show labels, laptops show the rail —
  /// so the shell adapts until the operator overrides it, and then it obeys.
  bool? _navCollapsed;

  /// The office's resolved entitlements, kept live for the sidebar.
  ///
  /// A HINT for the shell, nothing more — the same sentence
  /// [OfficeContext.isPlatformAdmin] carries. Every module it reveals is
  /// re-checked server-side, so a forged `true` here reaches a screen whose
  /// every write is refused by a trigger.
  /// Resolved only if registered. A test that mounts the shell with a minimal
  /// DI graph gets no service and therefore [EntitlementContext.unknown], which
  /// allows everything — the licensing axis must never be what decides whether
  /// the console can be built at all.
  final EntitlementService? _entitlements =
      dashboardDi.isRegistered<EntitlementService>()
      ? dashboardDi<EntitlementService>()
      : null;

  EntitlementContext get _entitlementContext =>
      _entitlements?.context ?? EntitlementContext.unknown;

  /// One instance across all seven licensing routes.
  ///
  /// Held here rather than created per route because the sections read each
  /// other constantly, and a `BlocProvider(create:)` in the route switch would
  /// refetch the whole catalog on every tab change.
  PlatformLicensingCubit? _licensingCubit;

  PlatformLicensingCubit get _licensing =>
      _licensingCubit ??= dashboardDi<PlatformLicensingCubit>()..load();

  @override
  void initState() {
    super.initState();
    _entitlements?.addListener(_onEntitlementsChanged);
    licensingRefusals.addListener(_onLicensingRefusal);
  }

  @override
  void dispose() {
    _entitlements?.removeListener(_onEntitlementsChanged);
    licensingRefusals.removeListener(_onLicensingRefusal);
    _licensingCubit?.close();
    super.dispose();
  }

  /// The upgrade moment (§10.3), raised once from the shell rather than in every
  /// screen that can hit a limit.
  ///
  /// The data layer announces a refusal on [licensingRefusals] the instant it
  /// maps one; the feature screen still shows its own snackbar with the Arabic
  /// sentence, and this puts the card with the real numbers on top of it. One
  /// wiring point, so a new module cannot forget to have an upgrade path.
  ///
  /// It also refreshes the document: the server just disagreed with what we
  /// hold, so by definition the copy in memory is out of date.
  void _onLicensingRefusal() {
    final failure = licensingRefusals.consume();
    if (failure == null || !mounted) return;

    _entitlements?.refresh();

    showLicensingRefusal(
      context,
      failure: failure,
      entitlements: _entitlementContext,
    );
  }

  void _onEntitlementsChanged() {
    if (!mounted) return;
    setState(() {
      
      if (!_canOpenRoute(_route)) _route = DashboardRoutes.home;
    });
  }

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
      label: 'نظرة تنفيذية',
      route: DashboardRoutes.businessOverview,
      icon: DashboardIcons.businessOverview,
      selectedIcon: DashboardIcons.businessOverviewActive,
      permission: DashboardPermission.businessOverview,
    ),
    _DashboardNavItem(
      label: 'العمليات المباشرة',
      route: DashboardRoutes.liveOps,
      icon: DashboardIcons.liveOps,
      selectedIcon: DashboardIcons.liveOpsActive,
      permission: DashboardPermission.liveOps,
      feature: FeatureKeys.liveOpsCenter,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'الرحلات',
      route: DashboardRoutes.trips,
      icon: DashboardIcons.trips,
      selectedIcon: DashboardIcons.tripsActive,
      permission: DashboardPermission.trips,
      feature: FeatureKeys.trips,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'المسارات',
      route: DashboardRoutes.routes,
      icon: DashboardIcons.routes,
      selectedIcon: DashboardIcons.routesActive,
      permission: DashboardPermission.routes,
      feature: FeatureKeys.routes,
      group: _navOperations,
    ),
    _DashboardNavItem(
      label: 'الحجوزات',
      route: DashboardRoutes.bookings,
      icon: DashboardIcons.bookings,
      selectedIcon: DashboardIcons.bookingsActive,
      permission: DashboardPermission.bookings,
      feature: FeatureKeys.bookings,
      group: _navSales,
    ),
    _DashboardNavItem(
      label: 'الاشتراكات',
      route: DashboardRoutes.subscriptions,
      icon: DashboardIcons.subscriptions,
      selectedIcon: DashboardIcons.subscriptionsActive,
      permission: DashboardPermission.subscriptions,
      feature: FeatureKeys.passengerPackages,
      group: _navSales,
    ),
    _DashboardNavItem(
      
      label: 'إدارة الأسطول',
      route: DashboardRoutes.fleet,
      icon: DashboardIcons.fleet,
      selectedIcon: DashboardIcons.fleetActive,
      permission: DashboardPermission.fleet,
      feature: FeatureKeys.drivers,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'طلبات الكباتن',
      route: DashboardRoutes.captainRequests,
      icon: DashboardIcons.captainRequests,
      selectedIcon: DashboardIcons.captainRequestsActive,
      permission: DashboardPermission.captainRequests,
      
      feature: FeatureKeys.driverApp,
      group: _navFleet,
    ),
    _DashboardNavItem(
      label: 'المدفوعات',
      route: DashboardRoutes.payments,
      icon: DashboardIcons.payments,
      selectedIcon: DashboardIcons.paymentsActive,
      permission: DashboardPermission.payments,
      feature: FeatureKeys.finance,
      group: _navFinance,
    ),
    _DashboardNavItem(
      
      label: 'محفظة العملاء',
      route: DashboardRoutes.wallet,
      icon: DashboardIcons.wallet,
      selectedIcon: DashboardIcons.walletActive,
      permission: DashboardPermission.customerWallets,
      feature: FeatureKeys.wallet,
      group: _navFinance,
    ),

    _DashboardNavItem(
      label: 'الشكاوى',
      route: DashboardRoutes.tickets,
      icon: DashboardIcons.tickets,
      selectedIcon: DashboardIcons.ticketsActive,
      permission: DashboardPermission.tickets,
      feature: FeatureKeys.supportTickets,
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
      feature: FeatureKeys.notifications,
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
      label: 'الباقة والفوترة',
      route: DashboardRoutes.officeBilling,
      icon: DashboardIcons.officeBilling,
      selectedIcon: DashboardIcons.officeBillingActive,
      permission: DashboardPermission.officeBilling,
      group: _navSystem,
    ),
    _DashboardNavItem(
      label: 'مكاتب المنصة',
      route: DashboardRoutes.platformOffices,
      icon: DashboardIcons.platformOffices,
      selectedIcon: DashboardIcons.platformOfficesActive,
      permission: DashboardPermission.platformOffices,
      
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'الخطط والباقات',
      route: DashboardRoutes.platformPlans,
      icon: DashboardIcons.plans,
      selectedIcon: DashboardIcons.plansActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'كتالوج الميزات',
      route: DashboardRoutes.platformFeatures,
      icon: DashboardIcons.featureCatalog,
      selectedIcon: DashboardIcons.featureCatalogActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'التراخيص',
      route: DashboardRoutes.platformLicenses,
      icon: DashboardIcons.licenses,
      selectedIcon: DashboardIcons.licensesActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'الفوترة',
      route: DashboardRoutes.platformBilling,
      icon: DashboardIcons.billing,
      selectedIcon: DashboardIcons.billingActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'الاستخدام',
      route: DashboardRoutes.platformUsage,
      icon: DashboardIcons.usage,
      selectedIcon: DashboardIcons.usageActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
    ),
    _DashboardNavItem(
      label: 'سجل التغييرات',
      route: DashboardRoutes.platformAudit,
      icon: DashboardIcons.audit,
      selectedIcon: DashboardIcons.auditActive,
      permission: DashboardPermission.platformLicensing,
      platformOnly: true,
      group: _navPlatform,
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
    final lockedRoutes = {
      for (final item in visibleItems)
        if (_isItemLocked(item)) item.route,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < _drawerBreakpoint;
        
        final collapsed =
            _navCollapsed ?? (constraints.maxWidth < _railBreakpoint);

        if (useDrawer) {
          return Scaffold(
            drawer: Drawer(
              child: SafeArea(
                
                child: _DashboardSidebar(
                  items: visibleItems,
                  lockedRoutes: lockedRoutes,
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
                  lockedRoutes: lockedRoutes,
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

  /// What the sidebar draws: everything the role permits, minus the modules the
  /// office cannot buy, plus the ones it can (drawn locked — see [_isItemLocked]).
  List<_DashboardNavItem> get _visibleItems {
    return _items
        .where((item) => _isItemAllowed(item) || _isItemLocked(item))
        .toList();
  }

  bool _isItemAllowed(_DashboardNavItem item) {
    if (!_passesRoleGate(item)) return false;
    
    return _entitlementContext.allows(item.feature);
  }

  bool _isItemLocked(_DashboardNavItem item) {
    if (!_passesRoleGate(item)) return false;
    return _entitlementContext.isLocked(item.feature);
  }

  bool _passesRoleGate(_DashboardNavItem item) {
    if (item.platformOnly && !widget.office.isPlatformAdmin) return false;
    final permission = item.permission;
    return permission == null ||
        DashboardPermissions.canAccess(_role, permission);
  }

  _DashboardNavItem get _activeItem => _items.firstWhere(
    (item) => item.route == _route,
    orElse: () => _items.first,
  );

  String get _activeTitle => _activeItem.label;

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
      
      final locked = _items.firstWhere(
        (item) => item.route == route && _isItemLocked(item),
        orElse: () => _items.first,
      );
      if (locked.route == route && _isItemLocked(locked)) {
        showLicensingRefusal(
          context,
          failure: LicensingFailure(
            code: LicensingFailure.featureNotLicensed,
            message:
                LicensingFailure.messages[LicensingFailure.featureNotLicensed]!,
            featureKey: locked.feature,
          ),
          entitlements: _entitlementContext,
        );
        return false;
      }

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
      DashboardRoutes.businessOverview => BlocProvider(
        create: (_) => dashboardDi<BusinessOverviewCubit>()..load(),
        child: BusinessOverviewScreen(
          office: widget.office,
          
          entitlements: _entitlementContext,
          
          canOpenRoute: _canOpenRoute,
          onOpenModule: _openRoute,
          onCreateTrip: _startTripPlanner,
        ),
      ),
      DashboardRoutes.liveOps => BlocProvider(
        create: (_) => dashboardDi<LiveOpsCubit>()..startWatching(),
        child: LiveOpsScreen(
          
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
      DashboardRoutes.wallet => BlocProvider(
        create: (_) => dashboardDi<WalletCubit>()..load(),
        
        child: WalletScreen(
          canAdjust: DashboardPermissions.canAccess(
            widget.office.role,
            DashboardPermission.walletAdjustments,
          ),
          canApprove: DashboardPermissions.canAccess(
            widget.office.role,
            DashboardPermission.walletApprovals,
          ),
        ),
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
          
          canEdit: widget.office.role == DashboardRole.admin,
        ),
      ),
      DashboardRoutes.platformOffices => BlocProvider(
        create: (_) => dashboardDi<PlatformAdminCubit>()..load(),
        child: const PlatformOfficesScreen(),
      ),
      DashboardRoutes.platformPlans => BlocProvider.value(
        value: _licensing,
        child: const PlatformPlansScreen(),
      ),
      DashboardRoutes.platformFeatures => BlocProvider.value(
        value: _licensing,
        child: const PlatformFeaturesScreen(),
      ),
      DashboardRoutes.platformLicenses => BlocProvider.value(
        value: _licensing,
        child: const PlatformLicensesScreen(),
      ),
      DashboardRoutes.platformBilling => BlocProvider.value(
        value: _licensing,
        child: const PlatformBillingScreen(),
      ),
      DashboardRoutes.platformUsage => BlocProvider.value(
        value: _licensing,
        child: const PlatformUsageScreen(),
      ),
      DashboardRoutes.platformAudit => BlocProvider.value(
        value: _licensing,
        child: const PlatformAuditScreen(),
      ),
      DashboardRoutes.officeBilling => BlocProvider(
        create: (_) => dashboardDi<OfficeBillingCubit>()..load(),
        child: const OfficeBillingScreen(),
      ),
      DashboardRoutes.settings => const SettingsScreen(),
      
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

  /// The licensing feature this module needs, if any.
  ///
  /// The THIRD predicate of `role ∧ entitlement ∧ quota`, kept separate from
  /// [permission] rather than merged into it. They change for different reasons
  /// — a role when staff change, an entitlement when a contract changes — and
  /// merged, the shell could no longer tell an operator *which* of the two
  /// refused them, which is the one question a licensing UI must always answer.
  final String? feature;

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
    this.feature,
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

  /// Routes present but not purchased. Drawn locked; the tap still goes through
  /// [onRouteChanged], which turns it into the upgrade card.
  final Set<String> lockedRoutes;

  const _DashboardSidebar({
    required this.items,
    required this.office,
    required this.role,
    required this.route,
    required this.onRouteChanged,
    this.collapsed = false,
    required this.onRoleChanged,
    this.onToggleCollapsed,
    this.lockedRoutes = const {},
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
    locked: lockedRoutes.contains(item.route),
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

  /// Purchasable but not owned (§10.2). Still tappable on purpose — the tap is
  /// how the owner finds out what the module is and what it would cost, which
  /// is the entire reason it is shown rather than hidden.
  final bool locked;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseInk = selected
        ? DashboardColors.sidebarSelectedInk(context)
        : DashboardColors.sidebarInk(context);
    
    final ink = locked ? baseInk.withValues(alpha: 0.55) : baseInk;
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
                    if (locked)
                      Icon(DashboardIcons.locked, size: 14, color: ink),
                  ],
                ),
        ),
      ),
    );

    if (!collapsed && !locked) return button;
    return Tooltip(
      message: locked
          ? '${item.label} — غير متاحة في باقتك الحالية'
          : item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: button,
    );
  }
}
