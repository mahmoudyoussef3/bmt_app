import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  drivers,
  fleet,
  assignments,
  vehicles,
  routes,
  trips,
  liveTrips,
  bookings,
  subscriptions,
  referrals,
  payments,
  paymentVerification,
  tickets,
  reports,
  ownerOverview,
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
      },
    };
  }
}
