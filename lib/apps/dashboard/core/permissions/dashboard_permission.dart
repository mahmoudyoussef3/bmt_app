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
  bookings,
  subscriptions,
  referrals,
  payments,
  paymentVerification,
  tickets,
  // Individual passenger reviews (with their written feedback) are for the
  // owner only — deliberately absent from the support-agent set below.
  reviews,
  reports,
  ownerOverview,
  notifications,
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
        DashboardPermission.bookings,
        DashboardPermission.tickets,
        DashboardPermission.reports,
        DashboardPermission.paymentVerification,
        DashboardPermission.notifications,
      },
    };
  }
}
