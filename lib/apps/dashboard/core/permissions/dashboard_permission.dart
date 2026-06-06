import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  drivers,
  vehicles,
  routes,
  trips,
  liveTrips,
  bookings,
  subscriptions,
  payments,
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
        DashboardPermission.vehicles,
        DashboardPermission.users,
        DashboardPermission.payments,
        DashboardPermission.tickets,
        DashboardPermission.reports,
      },
    };
  }
}
