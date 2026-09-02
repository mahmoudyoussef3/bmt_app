import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/bookings/presentation/models/booking_queue_tab.dart';
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
import '../../features/live_ops/presentation/bloc/fleet_tracking_bloc.dart';
import '../../features/live_ops/presentation/bloc/fleet_tracking_event.dart';
import '../../features/live_ops/presentation/cubit/live_ops_cubit.dart';
import '../../features/live_ops/presentation/screens/live_ops_screen.dart';
import '../../features/customers/presentation/cubit/customers_cubit.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
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
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/referrals/presentation/cubit/referral_cubit.dart';
import '../../features/referrals/presentation/screens/referral_management_screen.dart';
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
import '../../features/platform_licensing/presentation/screens/platform_billing_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_catalog_screen.dart';
import '../../features/platform_licensing/presentation/screens/platform_licenses_screen.dart';
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
const double _sidebarWidth = 256;
const double _sidebarRailWidth = 76;

/// Width of the same sidebar when it is the drawer instead of the frame.
/// Wider than the docked rail on purpose: a drawer is the only thing on
/// screen while it is open, so labels get the room the frame cannot spare.
const double _drawerWidth = 288;

/// Below this the shell swaps the sidebar for a drawer; between it and
/// [_railBreakpoint] the sidebar defaults to the icon rail, because a 256px
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
      label: 'التقارير',
      route: DashboardRoutes.reports,
      icon: DashboardIcons.reports,
      selectedIcon: DashboardIcons.reportsActive,
      permission: DashboardPermission.reports,
      feature: FeatureKeys.reports,
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
    // العملاء closes المبيعات: الحجوزات and الاشتراكات are what the office
    // sells, and this is who it sold them to. It carries no `feature:` — the
    // module aggregates data the office already owns rather than adding a
    // capability, so there is nothing here to license or to lock.
    _DashboardNavItem(
      label: 'العملاء',
      route: DashboardRoutes.customers,
      icon: DashboardIcons.customers,
      selectedIcon: DashboardIcons.customersActive,
      permission: DashboardPermission.customers,
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
      label: 'الباقات والميزات',
      route: DashboardRoutes.platformCatalog,
      icon: DashboardIcons.plans,
      selectedIcon: DashboardIcons.plansActive,
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
      label: 'الفوترة والسجل',
      route: DashboardRoutes.platformBilling,
      icon: DashboardIcons.billing,
      selectedIcon: DashboardIcons.billingActive,
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

    _DashboardNavItem(
      label: 'برنامج الإحالة',
      route: DashboardRoutes.referrals,
      icon: DashboardIcons.referrals,
      selectedIcon: DashboardIcons.referralsActive,
      permission: DashboardPermission.referrals,

      /// The referral programme carries no `office_id` — `referrals`,
      /// `referral_codes` and `referral_rewards` are platform-wide, and
      /// `referral_rewards` only accepts writes from `is_platform_admin()`.
      /// An office owner opening this would be reading the whole platform's
      /// numbers, so it belongs to EWT's own console and nowhere else.
      platformOnly: true,
      group: _navPlatform,
    ),

    // ── Reachable, but not sidebar destinations ──────────────────────────────
    //
    // Every route [_buildContent] can render must appear in this list, whether
    // or not it is drawn. The role and licensing gates are keyed on it, and a
    // route missing from it used to fall back to the *home* item — which
    // permits everything, so an unlisted route was reachable by any role. The
    // ones below are drilled into from cards on Home and نظرة تنفيذية rather
    // than navigated to, so they are registered and hidden, not omitted.
    _DashboardNavItem(
      label: 'السائقون',
      route: DashboardRoutes.drivers,
      icon: DashboardIcons.captains,
      selectedIcon: DashboardIcons.captainsActive,
      permission: DashboardPermission.drivers,
      feature: FeatureKeys.drivers,
      group: _navFleet,
      inSidebar: false,
    ),
    _DashboardNavItem(
      label: 'المركبات',
      route: DashboardRoutes.vehicles,
      icon: DashboardIcons.fleet,
      selectedIcon: DashboardIcons.fleetActive,
      permission: DashboardPermission.vehicles,
      feature: FeatureKeys.drivers,
      group: _navFleet,
      inSidebar: false,
    ),
    _DashboardNavItem(
      label: 'مراجعة المدفوعات',
      route: DashboardRoutes.paymentVerification,
      icon: DashboardIcons.paymentReview,
      selectedIcon: DashboardIcons.paymentReviewActive,
      permission: DashboardPermission.paymentVerification,
      feature: FeatureKeys.bookings,
      group: _navFinance,
      inSidebar: false,
    ),
    _DashboardNavItem(
      label: 'المستخدمون والصلاحيات',
      route: DashboardRoutes.users,
      icon: DashboardIcons.users,
      selectedIcon: DashboardIcons.usersActive,
      permission: DashboardPermission.permissions,
      group: _navSystem,
      inSidebar: false,
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
              width: _drawerWidth,
              backgroundColor: DashboardColors.sidebar(context),
              surfaceTintColor: Colors.transparent,
              // Only the inner edge is rounded — the outer one is flush with
              // the screen, so rounding it would float the drawer off nothing.
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.horizontal(
                  end: Radius.circular(AppTokens.radiusLarge),
                ),
              ),
              child: SafeArea(
                child: _DashboardSidebar(
                  items: visibleItems,
                  lockedRoutes: lockedRoutes,
                  office: widget.office,
                  role: _role,
                  route: _route,
                  collapsed: false,
                  expandedWidth: _drawerWidth,
                  onRoleChanged: _setRole,
                  onClose: () => Navigator.of(context).maybePop(),
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
        .where(
          (item) =>
              item.inSidebar && (_isItemAllowed(item) || _isItemLocked(item)),
        )
        .toList();
  }

  /// The registered item for [route], or null when the console has no such
  /// destination. Null is a refusal, never a fallback — see [_canOpenRoute].
  _DashboardNavItem? _itemFor(String route) {
    for (final item in _items) {
      if (item.route == route) return item;
    }
    return null;
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

  /// The open module, or the home item when the route is somehow unregistered —
  /// which [_openRoute] no longer allows, so this is a render-time backstop for
  /// [widget.initialRoute] rather than a path the console can navigate into.
  _DashboardNavItem get _activeItem => _itemFor(_route) ?? _items.first;

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
      final target = _itemFor(route);
      if (target != null && _isItemLocked(target)) {
        showLicensingRefusal(
          context,
          failure: LicensingFailure(
            code: LicensingFailure.featureNotLicensed,
            message:
                LicensingFailure.messages[LicensingFailure.featureNotLicensed]!,
            featureKey: target.feature,
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

  /// «مكاتب المنصة» → this office's feature board in «التراخيص».
  ///
  /// The hand-off is a route change plus a selection rather than a route
  /// argument, because the licensing console is one long-lived cubit shared by
  /// all three of its destinations: telling it which office to open *is* the
  /// navigation. [PlatformLicensingCubit.openOffice] waits for a load already
  /// in flight, so the jump lands on the office even when التراخيص has not been
  /// visited yet this session.
  void _openOfficeFeatures(String officeId) {
    if (!_openRoute(DashboardRoutes.platformLicenses)) return;
    unawaited(_licensing.openOffice(officeId));
  }

  /// The console's gate, and it fails **closed**.
  ///
  /// It used to resolve an unknown route to `_items.first` — the home item,
  /// which carries no permission and no feature and therefore allows everyone.
  /// Every route the shell could render but the sidebar did not list (السائقون,
  /// المركبات, مراجعة المدفوعات, التقارير …) inherited that verdict, so a
  /// support agent tapping the drivers tile on Home walked straight into the
  /// fleet module their role forbids. Unregistered now means refused.
  bool _canOpenRoute(String route) {
    final item = _itemFor(route);
    return item != null && _isItemAllowed(item);
  }

  /// The gate and the title table, reachable without rendering the module
  /// behind them — mounting Reports or Fleet to assert who may open them would
  /// mean standing up those modules' whole cubit graphs.
  @visibleForTesting
  bool canOpenRouteForTest(String route) => _canOpenRoute(route);

  @visibleForTesting
  String? titleForRouteForTest(String route) => _itemFor(route)?.label;

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
      // Two state holders, deliberately: the cubit owns the roster and the
      // incident queue, the Bloc owns live positions. Keeping them apart is what
      // stops a bus moving from rebuilding the incident queue — see
      // `FleetTrackingBloc`.
      DashboardRoutes.liveOps => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => dashboardDi<LiveOpsCubit>()..startWatching(),
          ),
          BlocProvider(
            create: (_) =>
                dashboardDi<FleetTrackingBloc>()
                  ..add(const FleetTrackingStarted()),
          ),
        ],
        child: LiveOpsScreen(
          onOpenModule: _openRoute,
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
      DashboardRoutes.vehicles => BlocProvider(
        create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
        child: const FleetOverviewScreen(initialTab: FleetTab.vehicles),
      ),
      DashboardRoutes.routes => BlocProvider(
        create: (_) => dashboardDi<RoutesCubit>()..load(),
        child: const RoutesScreen(),
      ),
      DashboardRoutes.customers => BlocProvider(
        create: (_) => dashboardDi<CustomersCubit>()..load(),
        child: const CustomersScreen(),
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
      DashboardRoutes.payments => BlocProvider(
        create: (_) => dashboardDi<FinanceCubit>()..load(),
        child: FinanceScreen(onOpenModule: _openRoute),
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
      // مراجعة المدفوعات is a preset of الحجوزات, not a module. The two read the
      // same table through the same three RPCs; keeping two data layers over
      // one job meant two places to fix a bug and two ways for the same number
      // to disagree with itself. The route survives as the deep link it always
      // was — the Home tile and the نظرة تنفيذية KPI both point at it — and
      // lands on the review queue with the operator's other filters cleared.
      DashboardRoutes.paymentVerification => BlocProvider(
        create: (_) =>
            dashboardDi<BookingsCubit>()
              ..load(presetTab: BookingQueueTab.needsReview),
        child: const BookingsScreen(),
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
        child: PlatformOfficesScreen(onOpenFeatures: _openOfficeFeatures),
      ),
      DashboardRoutes.platformCatalog => BlocProvider.value(
        value: _licensing,
        child: const PlatformCatalogScreen(),
      ),
      DashboardRoutes.platformLicenses => BlocProvider.value(
        value: _licensing,
        child: const PlatformLicensesScreen(),
      ),
      DashboardRoutes.platformBilling => BlocProvider.value(
        value: _licensing,
        child: const PlatformBillingScreen(),
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

  /// Whether the sidebar draws a row for this route.
  ///
  /// `false` marks a destination the console can open but does not advertise —
  /// reached by drilling into a card on Home or نظرة تنفيذية. It is still
  /// listed, because [_items] is what the role and licensing gates are keyed
  /// on and what the top bar reads its title from; omitting it is what made an
  /// unlisted route both ungated and mistitled.
  final bool inSidebar;

  const _DashboardNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    this.permission,
    this.feature,
    this.group,
    this.platformOnly = false,
    this.inSidebar = true,
  });
}

class _DashboardSidebar extends StatefulWidget {
  final List<_DashboardNavItem> items;
  final OfficeContext office;
  final DashboardRole role;
  final String route;
  final bool collapsed;
  final ValueChanged<DashboardRole> onRoleChanged;
  final ValueChanged<String> onRouteChanged;
  final VoidCallback? onToggleCollapsed;

  /// Dismisses the drawer this sidebar is mounted in. `null` when it is the
  /// docked frame, which has nothing to close.
  final VoidCallback? onClose;

  /// Width while labels are showing — [_sidebarWidth] docked, [_drawerWidth]
  /// in the drawer. The collapsed rail is always [_sidebarRailWidth].
  final double expandedWidth;

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
    this.onClose,
    this.expandedWidth = _sidebarWidth,
    this.lockedRoutes = const {},
  });

  @override
  State<_DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<_DashboardSidebar> {
  String _searchQuery = '';

  /// Horizontal inset every block in the sidebar shares, so the header, the
  /// search field, the nav rows and the footer all sit on one vertical line.
  double get _inset => widget.collapsed ? AppSpacing.small : AppSpacing.medium;

  @override
  void didUpdateWidget(covariant _DashboardSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapsing to the rail takes the search field away with it. A query left
    // behind would keep filtering a list whose labels are no longer on screen —
    // the operator would see missing icons and no way to tell why.
    if (widget.collapsed && !oldWidget.collapsed && _searchQuery.isNotEmpty) {
      _searchQuery = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.collapsed ? _sidebarRailWidth : widget.expandedWidth;

    return AnimatedContainer(
      duration: AppTokens.motionBase,
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: DashboardColors.sidebar(context),
        // In the drawer the elevation already separates it from the page, and
        // a hairline under a rounded corner only shows the corner cutting it.
        border: widget.onClose != null
            ? null
            : BorderDirectional(
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
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: DashboardColors.divider(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            _inset,
            AppSpacing.medium,
            _inset,
            AppSpacing.medium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OfficeIdentityHeader(
                office: widget.office,
                collapsed: widget.collapsed,
                onToggleCollapsed: widget.onToggleCollapsed,
                onClose: widget.onClose,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(height: AppSpacing.medium),
                _NavSearchField(
                  value: _searchQuery,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ],
          ),
        ),
        divider,
        Expanded(child: _NavScrollArea(builder: _buildNavList)),
        divider,
        Padding(
          padding: EdgeInsets.fromLTRB(
            _inset,
            AppSpacing.small,
            _inset,
            AppSpacing.medium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kDebugMode && !widget.collapsed) ...[
                _RoleSelector(
                  role: widget.role,
                  onChanged: widget.onRoleChanged,
                ),
                const SizedBox(height: AppSpacing.small),
              ],
              _AccountFooter(
                office: widget.office,
                role: widget.role,
                collapsed: widget.collapsed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavList(BuildContext context, ScrollController controller) {
    final query = _searchQuery.trim();
    final searching = query.isNotEmpty && !widget.collapsed;

    // The group name counts as a match too: typing "المالية" should surface the
    // section, not come back empty because no single screen is called that.
    bool matches(_DashboardNavItem item) =>
        !searching ||
        item.label.contains(query) ||
        (item.group?.contains(query) ?? false);

    final topLevel = widget.items.where((i) => i.group == null && matches(i));
    final children = <Widget>[for (final item in topLevel) _navButton(item)];

    for (final group in _navGroupOrder) {
      final groupItems = widget.items.where((i) => i.group == group).toList();
      if (groupItems.isEmpty) continue;
      final visibleItems = groupItems.where(matches).toList();
      if (searching && visibleItems.isEmpty) continue;

      children.add(
        _NavSectionHeader(label: group, collapsed: widget.collapsed),
      );
      children.addAll((searching ? visibleItems : groupItems).map(_navButton));
    }

    if (children.isEmpty) {
      return _NavEmptyState(query: query, controller: controller);
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: _inset,
        vertical: AppSpacing.small,
      ),
      itemCount: children.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.xSmall),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _navButton(_DashboardNavItem item) {
    final selected = item.route == widget.route;
    final locked = widget.lockedRoutes.contains(item.route);
    void open() => widget.onRouteChanged(item.route);

    // The one row that carries a live number. The bell in the top bar already
    // reads this cubit; the nav row shows the same count so an operator who has
    // the sidebar open does not have to look up to know something is waiting.
    // Skipped when the module is locked — an unbuyable count is noise — and
    // when the cubit is absent, which is how a minimal test graph mounts.
    if (item.route == DashboardRoutes.notifications &&
        !locked &&
        dashboardDi.isRegistered<OperationalAlertsBadgeCubit>()) {
      return BlocProvider.value(
        value: dashboardDi<OperationalAlertsBadgeCubit>(),
        child: BlocBuilder<OperationalAlertsBadgeCubit, int>(
          builder: (context, count) => _NavButton(
            item: item,
            selected: selected,
            collapsed: widget.collapsed,
            locked: locked,
            badgeCount: count,
            onTap: open,
          ),
        ),
      );
    }

    return _NavButton(
      item: item,
      selected: selected,
      collapsed: widget.collapsed,
      locked: locked,
      onTap: open,
    );
  }
}

/// The scrolling body of the sidebar, with a fade at whichever end still has
/// items past it.
///
/// Nineteen destinations do not fit a laptop's viewport, and a list that ends
/// flush against a divider reads as finished. The fades are drawn only when
/// there is genuinely something beyond the edge, so a short list — a filtered
/// search, a support agent's shorter menu — shows none at all.
class _NavScrollArea extends StatefulWidget {
  const _NavScrollArea({required this.builder});

  final Widget Function(BuildContext, ScrollController) builder;

  @override
  State<_NavScrollArea> createState() => _NavScrollAreaState();
}

class _NavScrollAreaState extends State<_NavScrollArea> {
  final ScrollController _controller = ScrollController();

  bool _fadeTop = false;
  bool _fadeBottom = false;

  @override
  void initState() {
    super.initState();
    // Metrics only get announced when they *change*, so the very first layout —
    // an already-overflowing list nobody has scrolled yet — would never light
    // the bottom fade without this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _sync(_controller.position);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(ScrollMetrics metrics) {
    final fadeTop = metrics.extentBefore > 1;
    final fadeBottom = metrics.extentAfter > 1;
    if (fadeTop == _fadeTop && fadeBottom == _fadeBottom) return;

    // Notifications arrive mid-layout; setState has to wait for the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _fadeTop = fadeTop;
        _fadeBottom = fadeBottom;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final surface = DashboardColors.sidebar(context);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _sync(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _sync(notification.metrics);
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Scrollbar(
                controller: _controller,
                thickness: 4,
                radius: const Radius.circular(4),
                child: widget.builder(context, _controller),
              ),
            ),
            if (_fadeTop) _EdgeFade(color: surface, atTop: true),
            if (_fadeBottom) _EdgeFade(color: surface, atTop: false),
          ],
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.color, required this.atTop});

  final Color color;
  final bool atTop;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: atTop ? 0 : null,
      bottom: atTop ? null : 0,
      start: 0,
      end: 0,
      height: 20,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: atTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: atTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the nav list shows when a search matches nothing. Names the query back,
/// because the alternative — an empty panel — reads as a broken sidebar.
class _NavEmptyState extends StatelessWidget {
  const _NavEmptyState({required this.query, required this.controller});

  final String query;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.xLarge,
      ),
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 28,
          color: DashboardColors.faintInk(context),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'لا توجد شاشة باسم «$query»',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

/// Quick-jump filter across every nav item's label. Client-side only — the
/// sidebar has no more than a few dozen destinations, so there is nothing to
/// fetch and nothing to debounce.
class _NavSearchField extends StatefulWidget {
  const _NavSearchField({required this.value, required this.onChanged});

  /// Seeds the field. The controller owns the text from then on — the parent
  /// only ever hears about it through [onChanged].
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_NavSearchField> createState() => _NavSearchFieldState();
}

class _NavSearchFieldState extends State<_NavSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = _focusNode.hasFocus;
    final hasQuery = _controller.text.isNotEmpty;

    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      borderSide: BorderSide(color: color, width: width),
    );

    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          widget.onChanged(value);
          // Only to bring the clear button in and out; the filtering itself is
          // the parent's business.
          setState(() {});
        },
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'بحث سريع…',
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: DashboardColors.faintInk(context),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: focused
                ? DashboardColors.accentInk(context)
                : DashboardColors.faintInk(context),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: _clear,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: DashboardColors.mutedInk(context),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 32),
          filled: true,
          fillColor: DashboardColors.nested(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: outline(DashboardColors.border(context), 1),
          enabledBorder: outline(DashboardColors.border(context), 1),
          focusedBorder: outline(DashboardColors.accentInk(context), 1.4),
        ),
      ),
    );
  }
}

/// The section title above each nav group. Every group stays expanded, so
/// this is a plain label rather than an accordion trigger — its only job is
/// to separate one group's items from the next, which it does with the label
/// and a rule running out to the sidebar's edge. Collapsed to icons, the
/// label has nowhere to go, so only the rule survives — otherwise the rail
/// becomes nineteen undifferentiated icons.
class _NavSectionHeader extends StatelessWidget {
  final String label;
  final bool collapsed;

  const _NavSectionHeader({required this.label, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.small,
        ),
        child: Divider(height: 1, color: DashboardColors.divider(context)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.xSmall,
      ),
      child: Row(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.sidebarSectionInk(context),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Container(
              height: 1,
              color: DashboardColors.divider(context),
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = office.displayName.characters.isEmpty
        ? '؟'
        : office.displayName.characters.first;

    final avatar = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        initial,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final signOut = _SignOutButton(onPressed: () => _confirmSignOut(context));

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

    // Contained rather than loose on the sidebar's own colour: the footer is
    // the one block here that is about the person, not the navigation, and the
    // sign-out inside it is the only irreversible control in the frame.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DashboardColors.ink(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
            ),
          ),
          signOut,
        ],
      ),
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

/// Sign-out, drawn quiet and turning red only under the pointer.
///
/// It used to sit in the footer permanently red, which made the loudest colour
/// in the whole sidebar belong to the one control nobody is looking for. The
/// warning still arrives — on hover, and again in the confirm dialog.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return IconButton(
      tooltip: 'تسجيل الخروج',
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: const Icon(DashboardIcons.logout, size: 18),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.focused)
              ? error
              : DashboardColors.mutedInk(context),
        ),
        overlayColor: WidgetStateProperty.all(error.withValues(alpha: 0.10)),
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
  const _OfficeIdentityHeader({
    required this.office,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.onClose,
  });

  final OfficeContext office;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  /// Dismisses the drawer. Present only in drawer mode, where [onToggleCollapsed]
  /// is absent — a drawer has no rail to collapse to, it just closes.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
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
            color: DashboardColors.mutedInk(context),
          );

    final close = onClose == null
        ? null
        : IconButton(
            tooltip: 'إغلاق القائمة',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            color: DashboardColors.mutedInk(context),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: DashboardColors.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              _MarketplaceStatus(listed: office.isListed),
            ],
          ),
        ),
        ?toggle,
        ?close,
      ],
    );
  }
}

/// Whether this office is on the client marketplace, as a dot and a word.
///
/// It was a grey line of body text under the office name, which is the same
/// treatment the console gives a subtitle — so the one fact on this screen that
/// changes what riders can see read as decoration. A status is a status: it
/// gets the dot.
class _MarketplaceStatus extends StatelessWidget {
  const _MarketplaceStatus({required this.listed});

  final bool listed;

  @override
  Widget build(BuildContext context) {
    final style = DashboardColors.status(
      context,
      listed ? AppStatusTone.success : AppStatusTone.neutral,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: style.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            listed ? 'معروض في السوق' : 'غير معروض في السوق',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
              fontWeight: FontWeight.w600,
            ),
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
          DashboardStatusChip(label: role.label),
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

/// Debug-only role switch. Labelled and shrunk so it never reads as a feature
/// of the console — an owner in a release build never sees it at all.
class _RoleSelector extends StatelessWidget {
  final DashboardRole role;
  final ValueChanged<DashboardRole> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.science_outlined,
              size: 13,
              color: DashboardColors.faintInk(context),
            ),
            const SizedBox(width: 5),
            Text(
              'عرض كـ (تجريبي)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: DashboardColors.faintInk(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        SegmentedButton<DashboardRole>(
          // The tick eats a third of a 256px sidebar's width; the fill already
          // says which side is selected.
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: 4,
            ),
            textStyle: theme.textTheme.labelSmall,
          ),
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
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final _DashboardNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  /// Unread count to draw on the row, if this destination has one. `0` draws
  /// nothing — an empty badge is worse than no badge.
  final int badgeCount;

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
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final baseInk = selected
        ? DashboardColors.sidebarSelectedInk(context)
        : DashboardColors.sidebarInk(context);

    final ink = locked ? baseInk.withValues(alpha: 0.55) : baseInk;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    // The selected row's icon is the one place brand ink appears in the list —
    // a single mark, paired with the 2px edge, rather than a tinted row.
    final iconColor = selected && !locked
        ? DashboardColors.accentInk(context)
        : ink;

    Widget icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 20,
      color: iconColor,
    );

    // Collapsed there is no room for the pill, so the count rides the icon.
    if (collapsed && badgeCount > 0) {
      icon = Badge(
        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
        child: icon,
      );
    }

    // The selected row's fill is warm/lifted rather than brand-tinted — the
    // brand itself is spent entirely on this 2px inline edge, so the sidebar
    // never reads as a wall of blue the way a filled-blue selection would.
    final button = Container(
      decoration: BoxDecoration(
        border: selected
            ? BorderDirectional(
                start: BorderSide(
                  color: DashboardColors.navSelectedEdge(context),
                  width: 2,
                ),
              )
            : null,
      ),
      child: Material(
        color: selected
            ? DashboardColors.sidebarSelected(context)
            : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          mouseCursor: SystemMouseCursors.click,

          hoverColor: DashboardColors.tableRowHover(context),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start:
                  (collapsed ? AppSpacing.small : AppSpacing.medium) -
                  (selected ? 2 : 0),
              end: collapsed ? AppSpacing.small : AppSpacing.small,
              top: AppSpacing.small,
              bottom: AppSpacing.small,
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ink,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                      if (locked)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xSmall,
                            end: AppSpacing.xSmall,
                          ),
                          child: Icon(
                            DashboardIcons.locked,
                            size: 14,
                            color: ink,
                          ),
                        )
                      else if (badgeCount > 0)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xSmall,
                          ),
                          child: _NavBadge(count: badgeCount),
                        )
                      else
                        const SizedBox(width: AppSpacing.xSmall),
                    ],
                  ),
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

/// The count pill on a nav row. Brand fill, because it is a call to act on
/// something — the only element in the list allowed to be louder than its row.
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DashboardColors.accentFill(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
