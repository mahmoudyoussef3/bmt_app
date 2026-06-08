import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  packages,
  drivers,
  fleet,
  assignments,
  vehicles,
  routes,
  trips,
  liveTrips,
  bookings,
  subscriptions,
  payments,
  paymentVerification,
  tickets,
  reports,
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
      DashboardRole.customerService => const {
        DashboardPermission.bookings,
        DashboardPermission.trips,
        DashboardPermission.liveTrips,
        DashboardPermission.drivers,
        DashboardPermission.fleet,
        DashboardPermission.assignments,
        DashboardPermission.vehicles,
        DashboardPermission.routes,
        DashboardPermission.users,
        DashboardPermission.packages,
        DashboardPermission.subscriptions,
        DashboardPermission.payments,
        DashboardPermission.paymentVerification,
        DashboardPermission.tickets,
        DashboardPermission.reports,
      },
    };
  }
}
