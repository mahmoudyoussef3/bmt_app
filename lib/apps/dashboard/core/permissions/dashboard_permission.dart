import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  drivers,
  fleet,
  captainRequests,
  assignments,
  vehicles,
  routes,
  trips,

  liveOps,

  liveOpsIncidentAction,
  bookings,
  subscriptions,
  referrals,
  payments,
  paymentVerification,

  customerWallets,

  walletAdjustments,

  walletApprovals,
  tickets,

  reviews,
  reports,

  businessOverview,
  notifications,

  officeProfile,

  platformOffices,

  platformLicensing,

  officeBilling,
  settings,
  permissions,
}

class DashboardPermissions {
  const DashboardPermissions._();

  static bool canAccess(DashboardRole role, DashboardPermission permission) {
    return permissionsFor(role).contains(permission);
  }

  static Set<DashboardPermission> permissionsFor(DashboardRole role) {
    return switch (role) {
      DashboardRole.admin => DashboardPermission.values.toSet(),
      DashboardRole.supportAgent => const {
        DashboardPermission.liveOps,
        DashboardPermission.bookings,
        DashboardPermission.tickets,
        DashboardPermission.reports,
        DashboardPermission.paymentVerification,
        DashboardPermission.notifications,

        DashboardPermission.customerWallets,
      },
    };
  }
}
